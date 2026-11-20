import { createExecutionContext, env, waitOnExecutionContext } from 'cloudflare:test';
import { SignJWT, exportJWK, generateKeyPair, jwtVerify } from 'jose';

import { setOidcFetcher } from '../src/auth/oidc';
import { pkceChallenge, randomToken } from '../src/lib/crypto';
import worker from '../src/index';

export const ISSUER = 'https://idp.test/oidc';
export const ORIGIN = 'https://sound.tsudev.com';

/** IdP giả: ghi lại nonce của lần authorize gần nhất, ký id_token ES256. */
export const TSUDEV = new URL(ISSUER).origin;
const DAY_S = 24 * 3600;

/**
 * Trạng thái quyền lợi giả của tsudev.com (PRODUCT_POLICY 7.4):
 * - `proUntil` (giây Unix; 0 = chưa từng Pro). Mặc định Pro còn 1 năm để các test đồng bộ cũ vẫn đẩy được.
 * - `grant = false` ⇒ kênh RP trả 404 `unknown_subject` (grant OIDC quá 30 ngày).
 * - `status`: ghi đè kết quả kênh trạng thái (`'error'` ⇒ HTTP 503).
 * - `jwsOverride`: thay JWS trả về (kiểm từ chối JWS sai `aud`/hết hạn/sai chữ ký).
 */
export interface FakeEntitlementState {
  nonce: string;
  sub: string;
  proUntil: number;
  grant: boolean;
  status?: 'ok' | 'deleted' | 'unknown_subject' | 'error';
  jwsOverride?: (sign: (claims: Record<string, unknown>, opts?: { aud?: string; typ?: string; iat?: number; exp?: number; foreignKey?: boolean }) => Promise<string>) => Promise<string>;
  rpCalls: number;
  statusCalls: number;
  assertions: Record<string, unknown>[];
  lastHeaders?: Headers;
}

export async function fakeIdp(opts: { sub?: string; tamperNonce?: boolean; wrongAud?: boolean; proUntil?: number } = {}) {
  const { privateKey, publicKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'ES256', use: 'sig' };
  // Khoá RP của Sound Db (client assertion private_key_jwt) - sinh mỗi lần, không ghi vào repo.
  const rp = await generateKeyPair('ES256', { extractable: true });
  (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK = JSON.stringify({ ...(await exportJWK(rp.privateKey)), kid: 'sounddb-rp-test' });
  const foreign = await generateKeyPair('ES256');
  const state: FakeEntitlementState = {
    nonce: '',
    sub: opts.sub ?? 'tsudev-user-1',
    proUntil: opts.proUntil ?? Math.floor(Date.now() / 1000) + 365 * DAY_S,
    grant: true,
    rpCalls: 0,
    statusCalls: 0,
    assertions: [],
  };
  const sign = async (
    claims: Record<string, unknown>,
    o: { aud?: string; typ?: string; iat?: number; exp?: number; foreignKey?: boolean } = {},
  ) => {
    const iat = o.iat ?? Math.floor(Date.now() / 1000);
    return new SignJWT(claims)
      .setProtectedHeader({ alg: 'ES256', kid: 'k1', typ: o.typ ?? 'tsu-ent+jwt' })
      .setIssuer(ISSUER)
      .setAudience(o.aud ?? 'sounddb')
      .setSubject(state.sub)
      .setIssuedAt(iat)
      .setExpirationTime(o.exp ?? iat + 7 * DAY_S)
      .sign(o.foreignKey ? foreign.privateKey : privateKey);
  };
  const checkAssertion = async (init: RequestInit | undefined, aud: string) => {
    const h = new Headers(init?.headers);
    const token = h.get('Authorization')?.replace(/^Bearer /, '') ?? '';
    const { payload, protectedHeader } = await jwtVerify(token, rp.publicKey, { audience: aud, algorithms: ['ES256'] });
    if (payload.iss !== 'sounddb' || payload.sub !== 'sounddb' || !payload.jti) throw new Error('bad assertion');
    if (payload.exp! - Math.floor(Date.now() / 1000) > 300) throw new Error('assertion exp');
    state.assertions.push({ ...payload, kid: protectedHeader.kid });
    state.lastHeaders = h;
  };
  setOidcFetcher(async (url, init) => {
    const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json' } });
    if (url.startsWith(`${TSUDEV}/api/rp/entitlements/`) && url !== `${TSUDEV}/api/rp/entitlements/status`) {
      state.rpCalls++;
      try {
        await checkAssertion(init, `${TSUDEV}/api/rp/entitlements`);
      } catch {
        return json({ error: 'invalid_client' }, 401);
      }
      const sub = decodeURIComponent(url.slice(`${TSUDEV}/api/rp/entitlements/`.length));
      if (!state.grant || sub !== state.sub) return json({ error: 'unknown_subject' }, 404);
      const pro = state.proUntil > Date.now() / 1000;
      const claims = { pro_until: state.proUntil, pro_source: pro ? 'web' : null, donor: false, badge: pro ? 'pro' : 'none', devices_30d: 2 };
      return json({ jws: state.jwsOverride ? await state.jwsOverride(sign) : await sign(claims) });
    }
    if (url === `${TSUDEV}/api/rp/entitlements/status`) {
      state.statusCalls++;
      try {
        await checkAssertion(init, `${TSUDEV}/api/rp/entitlements/status`);
      } catch {
        return json({ error: 'invalid_client' }, 401);
      }
      if (state.status === 'error') return json({ error: 'unavailable' }, 503);
      const body = JSON.parse(String(init?.body)) as { client_id: string; subs: string[] };
      if (body.client_id !== 'sounddb') return json({ error: 'forbidden_client_id' }, 403);
      const results: Record<string, unknown> = {};
      for (const s of body.subs) {
        const st = s === state.sub ? (state.status ?? 'ok') : 'unknown_subject';
        results[s] = st === 'ok' ? { status: 'ok', pro_until: state.proUntil } : { status: st };
      }
      return json({ results });
    }
    if (url === `${ISSUER}/.well-known/openid-configuration`) {
      return json({
        issuer: ISSUER,
        authorization_endpoint: `${ISSUER}/auth`,
        token_endpoint: `${ISSUER}/token`,
        userinfo_endpoint: `${ISSUER}/me`,
        jwks_uri: `${ISSUER}/jwks`,
      });
    }
    if (url === `${ISSUER}/jwks`) return json({ keys: [jwk] });
    if (url === `${ISSUER}/token`) {
      const body = new URLSearchParams(String(init?.body));
      if (body.get('code') !== 'idp-code' || !body.get('code_verifier')) return json({ error: 'invalid_grant' }, 400);
      const idToken = await new SignJWT({ nonce: opts.tamperNonce ? 'other' : state.nonce })
        .setProtectedHeader({ alg: 'ES256', kid: 'k1' })
        .setIssuer(ISSUER)
        .setAudience(opts.wrongAud ? 'someone-else' : 'sounddb')
        .setSubject(state.sub)
        .setIssuedAt()
        .setExpirationTime('5m')
        .sign(privateKey);
      return json({ id_token: idToken, access_token: 'idp-access', token_type: 'Bearer' });
    }
    if (url === `${ISSUER}/me`) {
      return json({ sub: state.sub, email: 'nguoi.dung@vi.du', email_verified: true, name: 'Người Dùng', picture: 'https://cdn.example/a.png' });
    }
    return json({ error: 'not_found' }, 404);
  });
  return state;
}

export async function call(path: string, init: RequestInit = {}) {
  const ctx = createExecutionContext();
  const headers = new Headers(init.headers);
  if (!headers.has('CF-Connecting-IP')) headers.set('CF-Connecting-IP', `10.0.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}`);
  const res = await worker.fetch(new Request(`${ORIGIN}${path}`, { ...init, headers, redirect: 'manual' }), env, ctx);
  await waitOnExecutionContext(ctx);
  return res;
}

export function cookieValue(res: Response, name: string): string | null {
  for (const c of res.headers.getSetCookie()) {
    const [pair] = c.split(';');
    const [k, v] = pair!.split('=');
    if (k === name) return v ?? null;
  }
  return null;
}

/** Đi trọn luồng đăng nhập app, trả token. */
export async function appLogin(idp: { nonce: string }, redirectUri = 'http://127.0.0.1:53111/callback') {
  const verifier = randomToken(48);
  const appState = randomToken(20);
  const start = await call(
    `/auth/app/start?${new URLSearchParams({
      redirect_uri: redirectUri,
      state: appState,
      code_challenge: await pkceChallenge(verifier),
      code_challenge_method: 'S256',
    })}`,
  );
  const authorize = new URL(start.headers.get('Location')!);
  idp.nonce = authorize.searchParams.get('nonce')!;
  const binder = cookieValue(start, '__Host-sdb_login')!;
  const cb = await call(`/auth/callback?code=idp-code&state=${authorize.searchParams.get('state')}`, {
    headers: { Cookie: `__Host-sdb_login=${binder}` },
  });
  if (cb.status !== 302) return { start, authorize, cb, back: new URL('http://invalid/'), appState, verifier, token: cb, body: {} as Record<string, any> };
  const back = new URL(cb.headers.get('Location')!);
  const token = await call('/api/v1/auth/token', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'authorization_code',
      code: back.searchParams.get('code'),
      code_verifier: verifier,
      redirect_uri: redirectUri,
      device_name: 'Pixel thử',
      platform: 'android',
    }),
  });
  return { start, authorize, cb, back, appState, verifier, token, body: (await token.json()) as Record<string, any> };
}
