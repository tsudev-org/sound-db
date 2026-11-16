import { Hono, type Context } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import { z } from 'zod';

import type { AppEnv } from '../env';
import { audit, clientIp } from '../lib/audit';
import { ApiError } from '../lib/errors';
import { pkceChallenge, randomToken, sha256Hex, timingSafeEqual } from '../lib/crypto';
import { rateLimit } from '../lib/ratelimit';
import { authorizationUrl, exchangeCode } from './oidc';
import { isAllowedAppRedirect, safeReturnTo } from './redirects';
import {
  ACCESS_TTL_S,
  LOGIN_COOKIE,
  SESSION_COOKIE,
  WEB_SESSION_TTL_MS,
  issueAccessToken,
  newRefreshToken,
  newWebSession,
} from './tokens';

const LOGIN_TTL_MS = 10 * 60 * 1000;
const APP_CODE_TTL_MS = 60 * 1000;

const limitAuth = (c: Context<AppEnv>) => rateLimit(c.env.DB, `auth:${clientIp(c)}`, 30, 60_000);

async function beginLogin(
  c: Context<AppEnv>,
  kind: 'web' | 'app',
  extra: { appRedirect?: string; appState?: string; appChallenge?: string; returnTo?: string },
) {
  await limitAuth(c);
  const state = randomToken(24);
  const nonce = randomToken(24);
  const verifier = randomToken(48);
  // Gắn yêu cầu với ĐÚNG trình duyệt bắt đầu nó: chặn kẻ gian gửi đường dẫn
  // callback cho nạn nhân để đăng nhập nạn nhân vào tài khoản kẻ gian.
  const binder = randomToken(24);
  const t = Date.now();
  await c.env.DB.prepare(
    `INSERT INTO login_requests (state_hash, binder_hash, nonce, code_verifier, client_kind, app_redirect_uri, app_state,
       app_code_challenge, return_to, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      await sha256Hex(state),
      await sha256Hex(binder),
      nonce,
      verifier,
      kind,
      extra.appRedirect ?? null,
      extra.appState ?? null,
      extra.appChallenge ?? null,
      extra.returnTo ?? null,
      t,
      t + LOGIN_TTL_MS,
    )
    .run();
  setCookie(c, LOGIN_COOKIE, binder, { path: '/', secure: true, httpOnly: true, sameSite: 'Lax', maxAge: 600 });
  return c.redirect(await authorizationUrl(c.env, { state, nonce, challenge: await pkceChallenge(verifier) }), 302);
}

const appStart = z.object({
  redirect_uri: z.string().max(200),
  state: z.string().min(16).max(256).regex(/^[A-Za-z0-9_-]+$/),
  code_challenge: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
  code_challenge_method: z.literal('S256'),
});

const tokenBody = z.discriminatedUnion('grant_type', [
  z.object({
    grant_type: z.literal('authorization_code'),
    code: z.string().min(20).max(200),
    code_verifier: z.string().regex(/^[A-Za-z0-9._~-]{43,128}$/),
    redirect_uri: z.string().max(200),
    device_name: z.string().trim().min(1).max(80).default('Thiết bị'),
    platform: z.enum(['android', 'ios', 'macos', 'windows', 'linux', 'fuchsia']).default('android'),
  }),
  z.object({ grant_type: z.literal('refresh_token'), refresh_token: z.string().startsWith('sdbr_').max(100) }),
]);

export function userJson(u: {
  id: string;
  email: string | null;
  email_verified: number;
  display_name: string | null;
  avatar_url: string | null;
}) {
  return {
    id: u.id,
    email: u.email,
    email_verified: u.email_verified === 1,
    display_name: u.display_name ?? u.email ?? 'Người dùng',
    avatar_url: u.avatar_url,
  };
}

export const authRoutes = new Hono<AppEnv>();

authRoutes.get('/auth/web/start', (c) => beginLogin(c, 'web', { returnTo: safeReturnTo(c.req.query('return_to')) }));

authRoutes.get('/auth/app/start', async (c) => {
  const parsed = appStart.safeParse(c.req.query());
  if (!parsed.success || !isAllowedAppRedirect(parsed.data.redirect_uri)) {
    // KHÔNG chuyển hướng về redirect_uri chưa kiểm: trả lỗi ngay tại đây.
    throw new ApiError(400, 'invalid_request', 'Yêu cầu đăng nhập từ app không hợp lệ.');
  }
  return beginLogin(c, 'app', {
    appRedirect: parsed.data.redirect_uri,
    appState: parsed.data.state,
    appChallenge: parsed.data.code_challenge,
  });
});

authRoutes.get('/auth/callback', async (c) => {
  await limitAuth(c);
  const state = c.req.query('state');
  const binder = getCookie(c, LOGIN_COOKIE);
  deleteCookie(c, LOGIN_COOKIE, { path: '/', secure: true });
  if (!state || !binder) throw new ApiError(400, 'invalid_state', 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Hãy thử lại.');
  // Xóa NGAY khi đọc: mỗi state dùng đúng một lần.
  const req = await c.env.DB.prepare('DELETE FROM login_requests WHERE state_hash = ? RETURNING *')
    .bind(await sha256Hex(state))
    .first<{
      binder_hash: string;
      nonce: string;
      code_verifier: string;
      client_kind: 'web' | 'app';
      app_redirect_uri: string | null;
      app_state: string | null;
      app_code_challenge: string | null;
      return_to: string | null;
      expires_at: number;
    }>();
  if (!req || req.expires_at < Date.now() || !timingSafeEqual(req.binder_hash, await sha256Hex(binder))) {
    throw new ApiError(400, 'invalid_state', 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Hãy thử lại.');
  }
  const appError = (code: string) => {
    const url = new URL(req.app_redirect_uri!);
    url.searchParams.set('error', code);
    url.searchParams.set('state', req.app_state!);
    return c.redirect(url.toString(), 302);
  };
  const idpError = c.req.query('error');
  const code = c.req.query('code');
  if (idpError || !code) {
    if (req.client_kind === 'app') return appError(idpError === 'access_denied' ? 'access_denied' : 'login_failed');
    return c.redirect('/dang-nhap/?loi=tu-choi', 302);
  }

  const identity = await exchangeCode(c.env, code, req.code_verifier, req.nonce);
  const t = Date.now();
  const user = await c.env.DB.prepare(
    `INSERT INTO users (id, oidc_sub, email, email_verified, display_name, avatar_url, created_at, last_login_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(oidc_sub) DO UPDATE SET email = excluded.email, email_verified = excluded.email_verified,
       display_name = excluded.display_name, avatar_url = excluded.avatar_url, last_login_at = excluded.last_login_at
     RETURNING id`,
  )
    .bind(crypto.randomUUID(), identity.sub, identity.email, identity.emailVerified ? 1 : 0, identity.name, identity.picture, t, t)
    .first<{ id: string }>();
  const userId = user!.id;
  await audit(c, userId, 'login', req.client_kind);

  if (req.client_kind === 'app') {
    const appCode = randomToken(32);
    await c.env.DB.prepare(
      'INSERT INTO app_codes (code_hash, user_id, redirect_uri, code_challenge, expires_at) VALUES (?, ?, ?, ?, ?)',
    )
      .bind(await sha256Hex(appCode), userId, req.app_redirect_uri, req.app_code_challenge, t + APP_CODE_TTL_MS)
      .run();
    const url = new URL(req.app_redirect_uri!);
    url.searchParams.set('code', appCode);
    url.searchParams.set('state', req.app_state!);
    return c.redirect(url.toString(), 302);
  }
  const session = await newWebSession(c.env.DB, userId, c.req.header('User-Agent'));
  setCookie(c, SESSION_COOKIE, session, {
    path: '/',
    secure: true,
    httpOnly: true,
    sameSite: 'Lax',
    maxAge: WEB_SESSION_TTL_MS / 1000,
  });
  return c.redirect(safeReturnTo(req.return_to), 302);
});

authRoutes.post('/api/v1/auth/token', async (c) => {
  await limitAuth(c);
  const parsed = tokenBody.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw new ApiError(400, 'invalid_request', 'Yêu cầu cấp token không hợp lệ.');
  const body = parsed.data;
  const db = c.env.DB;
  const t = Date.now();
  let userId: string;
  let deviceId: string;

  if (body.grant_type === 'authorization_code') {
    const row = await db
      .prepare(
        `UPDATE app_codes SET used_at = ? WHERE code_hash = ? AND used_at IS NULL AND expires_at > ?
         RETURNING user_id, redirect_uri, code_challenge`,
      )
      .bind(t, await sha256Hex(body.code), t)
      .first<{ user_id: string; redirect_uri: string; code_challenge: string }>();
    if (
      !row ||
      row.redirect_uri !== body.redirect_uri ||
      !timingSafeEqual(row.code_challenge, await pkceChallenge(body.code_verifier))
    ) {
      throw new ApiError(400, 'invalid_grant', 'Mã đăng nhập không hợp lệ hoặc đã dùng. Hãy đăng nhập lại.');
    }
    userId = row.user_id;
    deviceId = crypto.randomUUID();
    await db
      .prepare('INSERT INTO devices (id, user_id, name, platform, created_at, last_seen_at) VALUES (?, ?, ?, ?, ?, ?)')
      .bind(deviceId, userId, body.device_name, body.platform, t, t)
      .run();
    await audit(c, userId, 'device_added', deviceId);
  } else {
    const hash = await sha256Hex(body.refresh_token);
    const row = await db
      .prepare(
        `SELECT r.device_id, r.user_id, r.used_at, r.expires_at, d.revoked_at
         FROM refresh_tokens r JOIN devices d ON d.id = r.device_id WHERE r.token_hash = ?`,
      )
      .bind(hash)
      .first<{ device_id: string; user_id: string; used_at: number | null; expires_at: number; revoked_at: number | null }>();
    if (!row || row.revoked_at !== null || row.expires_at < t) {
      throw new ApiError(401, 'invalid_grant', 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
    }
    // Đánh dấu đã dùng có điều kiện: hai lượt gọi song song chỉ một lượt thắng.
    const claimed = await db
      .prepare('UPDATE refresh_tokens SET used_at = ? WHERE token_hash = ? AND used_at IS NULL')
      .bind(t, hash)
      .run();
    if (row.used_at !== null || claimed.meta.changes !== 1) {
      // Token đã xoay mà bị dùng lại = có kẻ giữ bản sao ⇒ thu hồi cả thiết bị.
      await db.batch([
        db.prepare('UPDATE devices SET revoked_at = ? WHERE id = ?').bind(t, row.device_id),
        db.prepare('DELETE FROM refresh_tokens WHERE device_id = ?').bind(row.device_id),
      ]);
      await audit(c, row.user_id, 'refresh_reuse_revoked', row.device_id);
      throw new ApiError(401, 'invalid_grant', 'Phát hiện phiên đăng nhập bị dùng lại - thiết bị đã bị đăng xuất để an toàn.');
    }
    userId = row.user_id;
    deviceId = row.device_id;
    await db.prepare('UPDATE devices SET last_seen_at = ? WHERE id = ?').bind(t, deviceId).run();
  }

  const user = await db
    .prepare('SELECT id, email, email_verified, display_name, avatar_url FROM users WHERE id = ?')
    .bind(userId)
    .first<{ id: string; email: string | null; email_verified: number; display_name: string | null; avatar_url: string | null }>();
  if (!user) throw new ApiError(401, 'invalid_grant', 'Tài khoản không còn tồn tại.');
  return c.json({
    token_type: 'Bearer',
    access_token: await issueAccessToken(c.env, userId, deviceId),
    expires_in: ACCESS_TTL_S,
    refresh_token: await newRefreshToken(db, userId, deviceId),
    device_id: deviceId,
    user: userJson(user),
  });
});

authRoutes.post('/api/v1/auth/logout', async (c) => {
  const body = z.object({ refresh_token: z.string().max(100) }).safeParse(await c.req.json().catch(() => null));
  if (body.success) {
    const row = await c.env.DB.prepare('SELECT device_id, user_id FROM refresh_tokens WHERE token_hash = ?')
      .bind(await sha256Hex(body.data.refresh_token))
      .first<{ device_id: string; user_id: string }>();
    if (row) {
      await c.env.DB.batch([
        c.env.DB.prepare('UPDATE devices SET revoked_at = ? WHERE id = ?').bind(Date.now(), row.device_id),
        c.env.DB.prepare('DELETE FROM refresh_tokens WHERE device_id = ?').bind(row.device_id),
      ]);
      await audit(c, row.user_id, 'logout', row.device_id);
    }
  }
  return c.body(null, 204);
});

authRoutes.post('/api/v1/auth/web-logout', async (c) => {
  if (c.req.header('Origin') !== c.env.PUBLIC_ORIGIN || c.req.header('X-Sdb-Csrf') !== '1') {
    throw new ApiError(403, 'csrf', 'Yêu cầu bị chặn vì không đến từ trang Sound Db.');
  }
  const cookie = getCookie(c, SESSION_COOKIE);
  if (cookie) await c.env.DB.prepare('DELETE FROM web_sessions WHERE token_hash = ?').bind(await sha256Hex(cookie)).run();
  deleteCookie(c, SESSION_COOKIE, { path: '/', secure: true });
  return c.body(null, 204);
});
