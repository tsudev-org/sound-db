import { SignJWT, importJWK, type CryptoKey as JoseKey, type JWK } from 'jose';

import { idpFetch, verifyEntitlementJws } from '../auth/oidc';
import type { Env } from '../env';
import { randomToken } from '../lib/crypto';
import { ApiError } from '../lib/errors';

/**
 * Quyền lợi TsuDEV Pro (PRODUCT_POLICY 7, ADR-0005). Sound Db là RP của tsudev.com: máy chủ này - không phải app -
 * hỏi tsudev.com, đệm tối đa 24 giờ trong bảng `entitlements`, và kiểm Pro ở MÁY CHỦ trước mọi lượt đẩy (N4).
 *
 * - Kênh RP: `GET {tsudev}/api/rp/entitlements/{sub}` ⇒ `{"jws": ...}` (cần grant OIDC còn hạn; không ⇒ 404).
 * - Kênh trạng thái: `POST {tsudev}/api/rp/entitlements/status` ⇒ `pro_until` (không phụ thuộc grant) - dùng khi kênh
 *   RP trả `unknown_subject` và trước MỌI lần xoá vì hết Pro.
 * Cả hai xác thực bằng client assertion `private_key_jwt` (RFC 7523): `iss` = `sub` = client_id, `aud` = đúng URL kênh,
 * `exp` 120 giây, `jti` một lần.
 */
export const CACHE_MS = 24 * 3600 * 1000;
export const GRACE_MS = 90 * 24 * 3600 * 1000;
export const STATUS_MAX_SUBS = 100;

export interface Entitlement {
  proUntil: number;
  badge: string;
  devices30d: number;
  jws: string | null;
  jwsExp: number;
  fetchedAt: number;
}

export type SubjectStatus = { status: 'ok'; proUntil: number } | { status: 'deleted' } | { status: 'unknown_subject' };

export const rpConfigured = (env: Env) => !!env.RP_PRIVATE_JWK;
const tsudevOrigin = (env: Env) => new URL(env.OIDC_ISSUER).origin;
export const rpAudience = (env: Env) => `${tsudevOrigin(env)}/api/rp/entitlements`;
export const statusAudience = (env: Env) => `${rpAudience(env)}/status`;

let signing: { raw: string; key: JoseKey | Uint8Array; kid?: string } | null = null;

export async function clientAssertion(env: Env, aud: string): Promise<string> {
  const raw = env.RP_PRIVATE_JWK ?? '';
  if (signing?.raw !== raw) {
    const jwk = JSON.parse(raw) as JWK;
    if (jwk.kty !== 'EC' || jwk.crv !== 'P-256' || !jwk.d) throw new Error('rp_key');
    signing = { raw, key: await importJWK(jwk, 'ES256'), kid: jwk.kid };
  }
  return new SignJWT({})
    .setProtectedHeader(signing.kid ? { alg: 'ES256', typ: 'JWT', kid: signing.kid } : { alg: 'ES256', typ: 'JWT' })
    .setIssuer(env.OIDC_CLIENT_ID)
    .setSubject(env.OIDC_CLIENT_ID)
    .setAudience(aud)
    .setIssuedAt()
    .setExpirationTime('120s')
    .setJti(randomToken(24))
    .sign(signing.key);
}

const INSTALLATION_RE = /^[A-Za-z0-9_-]{22}$/;
const PLATFORM_RE = /^(android|ios|windows|macos|linux|web)$/;

/** Kênh RP. `null` = tsudev.com không cấp cho `sub` này (không grant / không tài khoản). Lỗi khác ⇒ ném. */
async function fetchJws(env: Env, sub: string, hint: { installation?: string; platform?: string }): Promise<string | null> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${await clientAssertion(env, rpAudience(env))}`,
    Accept: 'application/json',
  };
  if (hint.installation && INSTALLATION_RE.test(hint.installation)) headers['X-Tsu-Installation'] = hint.installation;
  if (hint.platform && PLATFORM_RE.test(hint.platform)) headers['X-Tsu-Platform'] = hint.platform;
  const res = await idpFetch(`${rpAudience(env)}/${encodeURIComponent(sub)}`, {
    headers,
    redirect: 'error',
    signal: AbortSignal.timeout(10_000),
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`rp_${res.status}`);
  const body = (await res.json()) as { jws?: unknown };
  if (typeof body.jws !== 'string') throw new Error('rp_body');
  return body.jws;
}

/** Kênh trạng thái. Lỗi mạng/HTTP/khung sai ⇒ ném (người gọi KHÔNG được xoá khi lỗi). */
export async function fetchSubjectStatus(env: Env, subs: string[]): Promise<Map<string, SubjectStatus>> {
  const res = await idpFetch(statusAudience(env), {
    method: 'POST',
    redirect: 'error',
    headers: {
      Authorization: `Bearer ${await clientAssertion(env, statusAudience(env))}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({ client_id: env.OIDC_CLIENT_ID, subs: subs.slice(0, STATUS_MAX_SUBS) }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new Error(`status_${res.status}`);
  const body = (await res.json()) as { results?: unknown };
  if (!body.results || typeof body.results !== 'object') throw new Error('status_body');
  const out = new Map<string, SubjectStatus>();
  for (const sub of subs) {
    const r = (body.results as Record<string, { status?: unknown; pro_until?: unknown } | undefined>)[sub];
    if (r?.status === 'ok' && typeof r.pro_until === 'number' && Number.isFinite(r.pro_until) && r.pro_until >= 0) {
      out.set(sub, { status: 'ok', proUntil: Math.floor(r.pro_until) * 1000 });
    } else if (r?.status === 'deleted') {
      out.set(sub, { status: 'deleted' });
    } else {
      out.set(sub, { status: 'unknown_subject' });
    }
  }
  return out;
}

interface Row {
  pro_until: number;
  badge: string;
  devices_30d: number;
  jws: string | null;
  jws_exp: number;
  fetched_at: number;
}

const fromRow = (r: Row): Entitlement => ({
  proUntil: r.pro_until,
  badge: r.badge,
  devices30d: r.devices_30d,
  jws: r.jws,
  jwsExp: r.jws_exp,
  fetchedAt: r.fetched_at,
});

async function save(env: Env, userId: string, e: Entitlement) {
  await env.DB.prepare(
    `INSERT INTO entitlements (user_id, pro_until, badge, devices_30d, jws, jws_exp, fetched_at) VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_id) DO UPDATE SET pro_until = excluded.pro_until, badge = excluded.badge,
       devices_30d = excluded.devices_30d, jws = excluded.jws, jws_exp = excluded.jws_exp, fetched_at = excluded.fetched_at`,
  )
    .bind(userId, e.proUntil, e.badge, e.devices30d, e.jws, e.jwsExp, e.fetchedAt)
    .run();
}

/**
 * Quyền lợi của tài khoản: đệm còn < 24 giờ thì dùng luôn (trừ `force`), không thì hỏi tsudev.com.
 * Hỏi lỗi mà đệm còn < 24 giờ ⇒ dùng đệm; hết đệm ⇒ 503 `entitlements_unavailable` (KHÔNG coi là hết Pro).
 * Chưa cấu hình khoá RP ⇒ coi là miễn phí (không có bằng chứng Pro thì không có Pro - N4).
 */
export async function getEntitlement(
  env: Env,
  userId: string,
  opts: { force?: boolean; installation?: string; platform?: string; now?: number } = {},
): Promise<Entitlement> {
  const now = opts.now ?? Date.now();
  const row = await env.DB.prepare(
    'SELECT pro_until, badge, devices_30d, jws, jws_exp, fetched_at FROM entitlements WHERE user_id = ?',
  )
    .bind(userId)
    .first<Row>();
  const cached = row ? fromRow(row) : null;
  if (cached && !opts.force && now - cached.fetchedAt < CACHE_MS) return cached;
  if (!rpConfigured(env)) return cached ?? { proUntil: 0, badge: 'none', devices30d: 0, jws: null, jwsExp: 0, fetchedAt: 0 };

  const user = await env.DB.prepare('SELECT oidc_sub FROM users WHERE id = ?').bind(userId).first<{ oidc_sub: string }>();
  if (!user) throw new ApiError(401, 'unauthenticated', 'Tài khoản không còn tồn tại.');
  try {
    const jws = await fetchJws(env, user.oidc_sub, opts);
    let fresh: Entitlement;
    if (jws) {
      const p = await verifyEntitlementJws(env, jws);
      if (p.sub !== user.oidc_sub) throw new Error('rp_sub_mismatch');
      const proUntil = typeof p.pro_until === 'number' && p.pro_until > 0 ? Math.floor(p.pro_until) * 1000 : 0;
      fresh = {
        proUntil,
        badge: typeof p.badge === 'string' ? p.badge.slice(0, 16) : 'none',
        devices30d: typeof p.devices_30d === 'number' ? Math.max(0, Math.floor(p.devices_30d)) : 0,
        jws,
        jwsExp: p.exp! * 1000,
        fetchedAt: now,
      };
    } else {
      // Không còn grant cho Sound Db: hỏi kênh trạng thái để biết `pro_until` (máy chủ vẫn kiểm được Pro).
      const st = (await fetchSubjectStatus(env, [user.oidc_sub])).get(user.oidc_sub);
      fresh = {
        proUntil: st?.status === 'ok' ? st.proUntil : 0,
        badge: 'none',
        devices30d: 0,
        jws: null,
        jwsExp: 0,
        fetchedAt: now,
      };
    }
    await save(env, userId, fresh);
    return fresh;
  } catch (e) {
    console.warn('entitlements_unavailable', e instanceof Error ? e.message.slice(0, 40) : 'error');
    if (cached && now - cached.fetchedAt < CACHE_MS) return cached;
    throw new ApiError(503, 'entitlements_unavailable', 'Chưa kiểm tra được gói TsuDEV Pro. Dữ liệu vẫn lưu trên thiết bị; thử lại sau.', 300);
  }
}

/** Gate Pro ở máy chủ (N4): không có Pro còn hạn ⇒ `402 pro_required`. */
export async function requirePro(env: Env, userId: string, now = Date.now()): Promise<Entitlement> {
  const e = await getEntitlement(env, userId, { now });
  if (e.proUntil > now) return e;
  throw new ApiError(402, 'pro_required', 'Đồng bộ và sao lưu đám mây cần TsuDEV Pro. Dữ liệu vẫn lưu đủ trên thiết bị.');
}
