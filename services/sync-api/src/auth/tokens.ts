import { SignJWT, jwtVerify } from 'jose';

import type { Env } from '../env';
import { ApiError } from '../lib/errors';
import { acceptedIssuers } from '../lib/hosts';
import { randomToken, sha256Hex } from '../lib/crypto';

export const ACCESS_TTL_S = 15 * 60;
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;
export const WEB_SESSION_TTL_MS = 14 * 24 * 60 * 60 * 1000;
const AUDIENCE = 'sounddb-api';

function key(env: Env) {
  if (!env.SESSION_SECRET || env.SESSION_SECRET.length < 32) {
    // Cố ý ồn ào: thiếu secret thì không cấp/kiểm được token nào.
    throw new ApiError(503, 'server_misconfigured', 'Máy chủ chưa cấu hình khóa phiên.');
  }
  return new TextEncoder().encode(env.SESSION_SECRET);
}

export async function issueAccessToken(env: Env, userId: string, deviceId: string): Promise<string> {
  return new SignJWT({ did: deviceId })
    .setProtectedHeader({ alg: 'HS256', typ: 'at+jwt' })
    .setIssuer(env.PUBLIC_ORIGIN)
    .setAudience(AUDIENCE)
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${ACCESS_TTL_S}s`)
    .setJti(randomToken(12))
    .sign(key(env));
}

export async function verifyAccessToken(env: Env, token: string): Promise<{ userId: string; deviceId: string }> {
  try {
    const { payload } = await jwtVerify(token, key(env), {
      issuer: acceptedIssuers(env),
      audience: AUDIENCE,
      algorithms: ['HS256'],
      typ: 'at+jwt',
    });
    if (typeof payload.sub !== 'string' || typeof payload.did !== 'string') throw new Error('claims');
    return { userId: payload.sub, deviceId: payload.did };
  } catch (e) {
    if (e instanceof ApiError) throw e;
    throw new ApiError(401, 'invalid_token', 'Phiên đăng nhập đã hết hạn.');
  }
}

/** Refresh token mờ, tiền tố để quét secret nhận ra; chỉ lưu SHA-256. */
export async function newRefreshToken(db: D1Database, userId: string, deviceId: string): Promise<string> {
  const token = `sdbr_${randomToken(32)}`;
  const t = Date.now();
  await db
    .prepare('INSERT INTO refresh_tokens (token_hash, device_id, user_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)')
    .bind(await sha256Hex(token), deviceId, userId, t, t + REFRESH_TTL_MS)
    .run();
  return token;
}

export async function newWebSession(db: D1Database, userId: string, userAgent: string | undefined): Promise<string> {
  const token = randomToken(32);
  const t = Date.now();
  await db
    .prepare('INSERT INTO web_sessions (token_hash, user_id, created_at, expires_at, user_agent) VALUES (?, ?, ?, ?, ?)')
    .bind(await sha256Hex(token), userId, t, t + WEB_SESSION_TTL_MS, (userAgent ?? '').slice(0, 200))
    .run();
  return token;
}

export const SESSION_COOKIE = '__Host-sdb_session';
export const LOGIN_COOKIE = '__Host-sdb_login';
