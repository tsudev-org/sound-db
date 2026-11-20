import { createLocalJWKSet, jwtVerify, type JSONWebKeySet, type JWTPayload } from 'jose';

import type { Env } from '../env';
import { ApiError } from '../lib/errors';

/**
 * Bên tin cậy (RP) OIDC của tsudev.com. Chỉ Authorization Code + PKCE S256,
 * client công khai `sounddb`, redirect DUY NHẤT `${PUBLIC_ORIGIN}/auth/callback`.
 * Cấu hình đọc từ discovery (không ghi cứng endpoint); JWKS cache theo `kid`,
 * gặp `kid` lạ thì tải lại (tối đa 1 lần/phút) - AUTH_AND_ACCOUNT.md mục 2.
 */
export interface Discovery {
  issuer: string;
  authorization_endpoint: string;
  token_endpoint: string;
  userinfo_endpoint: string;
  jwks_uri: string;
  end_session_endpoint?: string;
}

type Fetcher = (input: string, init?: RequestInit) => Promise<Response>;
let fetcher: Fetcher = (input, init) => fetch(input, init);

/** Chỉ dùng trong test: thay IdP thật bằng IdP giả. */
export function setOidcFetcher(f: Fetcher) {
  fetcher = f;
  discoveryCache = null;
  jwksCache = null;
}

let discoveryCache: { issuer: string; value: Discovery; at: number } | null = null;
let jwksCache: { uri: string; keys: JSONWebKeySet; at: number } | null = null;
const DISCOVERY_TTL = 60 * 60 * 1000;
const JWKS_MIN_REFRESH = 60 * 1000;

async function getJson<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetcher(url, { ...init, signal: AbortSignal.timeout(10_000) });
  if (!res.ok) throw new ApiError(502, 'idp_unavailable', `Máy chủ tài khoản TsuDEV trả lỗi ${res.status}.`);
  return (await res.json()) as T;
}

export async function discovery(env: Env): Promise<Discovery> {
  if (discoveryCache && discoveryCache.issuer === env.OIDC_ISSUER && Date.now() - discoveryCache.at < DISCOVERY_TTL) {
    return discoveryCache.value;
  }
  const value = await getJson<Discovery>(`${env.OIDC_ISSUER}/.well-known/openid-configuration`);
  if (value.issuer !== env.OIDC_ISSUER) {
    throw new ApiError(502, 'idp_misconfigured', 'Cấu hình nhà cung cấp danh tính không khớp issuer.');
  }
  discoveryCache = { issuer: env.OIDC_ISSUER, value, at: Date.now() };
  return value;
}

async function jwks(uri: string, force: boolean): Promise<JSONWebKeySet> {
  const fresh = jwksCache && jwksCache.uri === uri;
  if (fresh && (!force || Date.now() - jwksCache!.at < JWKS_MIN_REFRESH)) return jwksCache!.keys;
  const keys = await getJson<JSONWebKeySet>(uri);
  jwksCache = { uri, keys, at: Date.now() };
  return keys;
}

export function redirectUri(env: Env) {
  return `${env.PUBLIC_ORIGIN}/auth/callback`;
}

export async function authorizationUrl(env: Env, p: { state: string; nonce: string; challenge: string }) {
  const d = await discovery(env);
  const url = new URL(d.authorization_endpoint);
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: env.OIDC_CLIENT_ID,
    redirect_uri: redirectUri(env),
    scope: 'openid profile email',
    state: p.state,
    nonce: p.nonce,
    code_challenge: p.challenge,
    code_challenge_method: 'S256',
  }).toString();
  return url.toString();
}

export interface IdentityClaims {
  sub: string;
  email: string | null;
  emailVerified: boolean;
  name: string | null;
  picture: string | null;
}

/** Đổi mã lấy token (máy chủ - máy chủ), kiểm id_token, đọc userinfo. */
export async function exchangeCode(env: Env, code: string, verifier: string, nonce: string): Promise<IdentityClaims> {
  const d = await discovery(env);
  const res = await fetcher(d.token_endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri(env),
      client_id: env.OIDC_CLIENT_ID,
      code_verifier: verifier,
    }).toString(),
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new ApiError(401, 'idp_rejected', 'tsudev.com từ chối mã đăng nhập (có thể đã hết hạn). Hãy thử lại.');
  const tokens = (await res.json()) as { id_token?: string; access_token?: string };
  if (!tokens.id_token || !tokens.access_token) throw new ApiError(502, 'idp_bad_response', 'Phản hồi đăng nhập thiếu token.');

  let payload: JWTPayload;
  const verify = async (force: boolean) =>
    (
      await jwtVerify(tokens.id_token!, createLocalJWKSet(await jwks(d.jwks_uri, force)), {
        issuer: env.OIDC_ISSUER,
        audience: env.OIDC_CLIENT_ID,
        algorithms: ['ES256'],
        maxTokenAge: '15m',
        clockTolerance: 30,
      })
    ).payload;
  try {
    payload = await verify(false);
  } catch (e) {
    if ((e as { code?: string }).code !== 'ERR_JWKS_NO_MATCHING_KEY') throw invalidToken();
    try {
      payload = await verify(true);
    } catch {
      throw invalidToken();
    }
  }
  if (payload.nonce !== nonce || typeof payload.sub !== 'string') throw invalidToken();

  // Hồ sơ lấy ở userinfo (id_token của tsudev chỉ chở `sub`), và sub phải trùng.
  const info = await getJson<Record<string, unknown>>(d.userinfo_endpoint, {
    headers: { Authorization: `Bearer ${tokens.access_token}`, Accept: 'application/json' },
  });
  if (info.sub !== payload.sub) throw invalidToken();
  const str = (v: unknown) => (typeof v === 'string' && v.length <= 512 ? v : null);
  const picture = str(info.picture);
  return {
    sub: payload.sub,
    email: str(info.email),
    emailVerified: info.email_verified === true,
    name: str(info.name) ?? str(info.preferred_username),
    picture: picture && picture.startsWith('https://') ? picture : null,
  };
}

/**
 * Kiểm JWS quyền lợi do tsudev.com ký (PRODUCT_POLICY 7.4): ES256, `typ` = `tsu-ent+jwt`, `iss` = issuer OIDC,
 * `aud` = client của Sound Db, còn hạn, `exp` ≤ `iat` + 7 ngày. Khoá lấy từ cùng JWKS với id_token.
 */
export async function verifyEntitlementJws(env: Env, jws: string): Promise<JWTPayload> {
  const d = await discovery(env);
  const verify = async (force: boolean) =>
    (
      await jwtVerify(jws, createLocalJWKSet(await jwks(d.jwks_uri, force)), {
        issuer: env.OIDC_ISSUER,
        audience: env.OIDC_CLIENT_ID,
        algorithms: ['ES256'],
        typ: 'tsu-ent+jwt',
        requiredClaims: ['sub', 'iat', 'exp'],
        clockTolerance: 30,
      })
    ).payload;
  let p: JWTPayload;
  try {
    p = await verify(false);
  } catch (e) {
    if ((e as { code?: string }).code !== 'ERR_JWKS_NO_MATCHING_KEY') throw e;
    p = await verify(true);
  }
  if (p.exp! > p.iat! + 7 * 24 * 3600) throw new Error('entitlement_exp_too_long');
  return p;
}

/** fetch dùng chung với OIDC (test thay bằng IdP giả qua `setOidcFetcher`). */
export const idpFetch: Fetcher = (input, init) => fetcher(input, init);

function invalidToken() {
  return new ApiError(401, 'invalid_id_token', 'Không xác minh được danh tính trả về từ tsudev.com.');
}
