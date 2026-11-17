import { env } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

import { isAllowedAppRedirect, safeReturnTo } from '../src/auth/redirects';
import { appLogin, call, cookieValue, fakeIdp } from './helpers';

describe('đích quay về', () => {
  it('chỉ nhận scheme app và vòng lặp 127.0.0.1 khớp tuyệt đối', () => {
    expect(isAllowedAppRedirect('com.tsudev.sounddb:/auth/callback')).toBe(true);
    expect(isAllowedAppRedirect('http://127.0.0.1:53111/callback')).toBe(true);
    for (const bad of [
      'http://localhost:53111/callback',
      'http://127.0.0.1:53111/callback/x',
      'http://127.0.0.1:80/callback',
      'https://evil.example/callback',
      'com.tsudev.sounddb:/auth/callback?x=1',
      'com.tsudev.sounddb.evil:/auth/callback',
      'http://127.0.0.1.evil.example:53111/callback',
    ]) {
      expect(isAllowedAppRedirect(bad), bad).toBe(false);
    }
  });

  it('return_to chỉ là đường dẫn tương đối cùng gốc', () => {
    expect(safeReturnTo('/bang-dieu-khien/phien/')).toBe('/bang-dieu-khien/phien/');
    for (const bad of ['//evil.example', 'https://evil.example', '/\\evil', 'javascript:alert(1)', undefined]) {
      expect(safeReturnTo(bad)).toBe('/bang-dieu-khien/');
    }
  });
});

describe('đăng nhập app (PKCE + mã một lần)', () => {
  it('đi trọn luồng và cấp token', async () => {
    const idp = await fakeIdp();
    const r = await appLogin(idp);
    expect(r.start.status).toBe(302);
    expect(r.authorize.searchParams.get('code_challenge_method')).toBe('S256');
    expect(r.authorize.searchParams.get('redirect_uri')).toBe('https://sounddb.tsudev.com/auth/callback');
    expect(r.back.searchParams.get('state')).toBe(r.appState);
    expect(r.token.status).toBe(200);
    expect(r.body.refresh_token).toMatch(/^sdbr_/);
    expect(r.body.user.email).toBe('nguoi.dung@vi.du');
    const me = await call('/api/v1/me', { headers: { Authorization: `Bearer ${r.body.access_token}` } });
    expect(me.status).toBe(200);
    expect(((await me.json()) as any).display_name).toBe('Người Dùng');
  });

  it('từ chối redirect_uri ngoài danh sách mà KHÔNG chuyển hướng', async () => {
    await fakeIdp();
    const res = await call('/auth/app/start?redirect_uri=https%3A%2F%2Fevil.example%2Fcb&state=aaaaaaaaaaaaaaaaaaaa&code_challenge=' +
      'a'.repeat(43) + '&code_challenge_method=S256');
    expect(res.status).toBe(400);
    expect(res.headers.get('Location')).toBeNull();
  });

  it('callback thiếu cookie gắn trình duyệt bị chặn (chống CSRF đăng nhập)', async () => {
    await fakeIdp();
    const start = await call('/auth/web/start');
    const state = new URL(start.headers.get('Location')!).searchParams.get('state');
    const res = await call(`/auth/callback?code=idp-code&state=${state}`);
    expect(res.status).toBe(400);
  });

  it('nonce sai hoặc aud sai ⇒ không đăng nhập', async () => {
    for (const opt of [{ tamperNonce: true }, { wrongAud: true }]) {
      const idp = await fakeIdp(opt);
      const r = await appLogin(idp);
      expect(r.cb.status).toBe(401);
    }
  });

  it('mã app chỉ dùng một lần và phải đúng code_verifier', async () => {
    const idp = await fakeIdp();
    const r = await appLogin(idp);
    const again = await call('/api/v1/auth/token', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ grant_type: 'authorization_code', code: r.back.searchParams.get('code'), code_verifier: r.verifier, redirect_uri: 'http://127.0.0.1:53111/callback' }),
    });
    expect(again.status).toBe(400);

    const r2 = await appLogin(idp);
    expect(r2.token.status).toBe(200);
  });

  it('refresh xoay vòng; dùng lại token cũ ⇒ thu hồi thiết bị', async () => {
    const idp = await fakeIdp();
    const { body } = await appLogin(idp);
    const refresh = (t: string) =>
      call('/api/v1/auth/token', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ grant_type: 'refresh_token', refresh_token: t }) });
    const first = await refresh(body.refresh_token);
    expect(first.status).toBe(200);
    const rotated = (await first.json()) as any;
    expect(rotated.refresh_token).not.toBe(body.refresh_token);
    const replay = await refresh(body.refresh_token);
    expect(replay.status).toBe(401);
    // Cả token mới cũng chết vì thiết bị đã bị thu hồi.
    expect((await refresh(rotated.refresh_token)).status).toBe(401);
    const me = await call('/api/v1/me', { headers: { Authorization: `Bearer ${rotated.access_token}` } });
    expect(me.status).toBe(401);
    const audit = await env.DB.prepare("SELECT COUNT(*) AS n FROM audit_log WHERE event = 'refresh_reuse_revoked'").first<{ n: number }>();
    expect(audit!.n).toBeGreaterThan(0);
  });

  it('access token giả mạo bị từ chối', async () => {
    const res = await call('/api/v1/me', { headers: { Authorization: 'Bearer eyJhbGciOiJub25lIn0.eyJzdWIiOiJ4In0.' } });
    expect(res.status).toBe(401);
  });
});

describe('đăng nhập web (cookie)', () => {
  it('đặt cookie __Host- HttpOnly Secure và chặn ghi thiếu CSRF', async () => {
    const idp = await fakeIdp({ sub: 'web-user' });
    const start = await call('/auth/web/start?return_to=%2F%2Fevil.example');
    const authorize = new URL(start.headers.get('Location')!);
    idp.nonce = authorize.searchParams.get('nonce')!;
    const cb = await call(`/auth/callback?code=idp-code&state=${authorize.searchParams.get('state')}`, {
      headers: { Cookie: `__Host-sdb_login=${cookieValue(start, '__Host-sdb_login')}` },
    });
    expect(cb.status).toBe(302);
    expect(cb.headers.get('Location')).toBe('/bang-dieu-khien/');
    const raw = cb.headers.getSetCookie().find((c) => c.startsWith('__Host-sdb_session='))!;
    expect(raw).toMatch(/HttpOnly/);
    expect(raw).toMatch(/Secure/);
    expect(raw).toMatch(/SameSite=Lax/);
    const session = cookieValue(cb, '__Host-sdb_session');
    const cookie = { Cookie: `__Host-sdb_session=${session}` };
    expect((await call('/api/v1/me', { headers: cookie })).status).toBe(200);
    expect(await (await call('/api/v1/auth/status', { headers: cookie })).json()).toEqual({ signed_in: true });
    expect(await (await call('/api/v1/auth/status')).json()).toEqual({ signed_in: false });
    const noCsrf = await call('/api/v1/me', { method: 'DELETE', headers: { ...cookie, 'X-Sdb-Confirm': 'xoa-vinh-vien' } });
    expect(noCsrf.status).toBe(403);
    const ok = await call('/api/v1/me', {
      method: 'DELETE',
      headers: { ...cookie, Origin: 'https://sounddb.tsudev.com', 'X-Sdb-Csrf': '1', 'X-Sdb-Confirm': 'xoa-vinh-vien' },
    });
    expect(ok.status).toBe(204);
    expect((await call('/api/v1/me', { headers: cookie })).status).toBe(401);
  });
});

describe('header bảo mật', () => {
  it('API trả no-store, nosniff, CSP chặt', async () => {
    const res = await call('/api/v1/health');
    expect(res.headers.get('Cache-Control')).toBe('no-store');
    expect(res.headers.get('X-Content-Type-Options')).toBe('nosniff');
    expect(res.headers.get('Content-Security-Policy')).toContain("default-src 'none'");
  });
});
