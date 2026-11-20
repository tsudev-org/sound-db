import { createExecutionContext, env, waitOnExecutionContext } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

import { issueAccessToken, verifyAccessToken } from '../src/auth/tokens';
import type { Env } from '../src/env';
import { acceptedIssuers, aliasOrigins } from '../src/lib/hosts';
import worker from '../src/index';
import { ORIGIN } from './helpers';

const ALIAS = 'https://sounddb.tsudev.com';

async function at(url: string, init: RequestInit = {}) {
  const ctx = createExecutionContext();
  const res = await worker.fetch(new Request(url, { ...init, redirect: 'manual' }), env, ctx);
  await waitOnExecutionContext(ctx);
  return res;
}

describe('nhiều tên miền (ADR-0007)', () => {
  it('đọc ALIAS_ORIGINS, bỏ host chuẩn và dấu / cuối', () => {
    const e = { ...env, ALIAS_ORIGINS: ` ${ALIAS}/ ,${ORIGIN}, ` } as Env;
    expect(aliasOrigins(e)).toEqual([ALIAS]);
    expect(acceptedIssuers(e)).toEqual([ORIGIN, ALIAS]);
    expect(aliasOrigins({ ...env, ALIAS_ORIGINS: undefined } as Env)).toEqual([]);
  });

  it('/auth/* ở host phụ chuyển nguyên đường + query về host chuẩn (307)', async () => {
    const res = await at(`${ALIAS}/auth/web/start?return_to=%2Fbang-dieu-khien%2F`);
    expect(res.status).toBe(307);
    expect(res.headers.get('Location')).toBe(`${ORIGIN}/auth/web/start?return_to=%2Fbang-dieu-khien%2F`);
    expect(res.headers.get('Strict-Transport-Security')).toContain('max-age=');
  });

  it('host lạ không bị chuyển hướng sang host chuẩn (không thành open redirect ngược)', async () => {
    const res = await at('https://evil.example/auth/callback?state=x');
    expect(res.status).not.toBe(307);
    expect(res.headers.get('Location') ?? '').not.toContain(ORIGIN);
  });

  it('API vẫn chạy ở host phụ cho app đã cài', async () => {
    const res = await at(`${ALIAS}/api/v1/health`);
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ ok: true });
  });

  it('token có iss = host phụ vẫn hợp lệ (đảo host chuẩn không đăng xuất app); iss lạ bị từ chối', async () => {
    const fromAlias = await issueAccessToken({ ...env, PUBLIC_ORIGIN: ALIAS } as Env, 'u1', 'd1');
    await expect(verifyAccessToken(env as Env, fromAlias)).resolves.toEqual({ userId: 'u1', deviceId: 'd1' });
    const foreign = await issueAccessToken({ ...env, PUBLIC_ORIGIN: 'https://khac.tsudev.com' } as Env, 'u1', 'd1');
    await expect(verifyAccessToken(env as Env, foreign)).rejects.toMatchObject({ status: 401 });
  });
});
