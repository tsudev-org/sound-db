import { createExecutionContext, env, waitOnExecutionContext } from 'cloudflare:test';
import { SignJWT, exportJWK, generateKeyPair } from 'jose';

import { setOidcFetcher } from '../src/auth/oidc';
import { pkceChallenge, randomToken } from '../src/lib/crypto';
import worker from '../src/index';

export const ISSUER = 'https://idp.test/oidc';
export const ORIGIN = 'https://sounddb.tsudev.com';

/** IdP giả: ghi lại nonce của lần authorize gần nhất, ký id_token ES256. */
export async function fakeIdp(opts: { sub?: string; tamperNonce?: boolean; wrongAud?: boolean } = {}) {
  const { privateKey, publicKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'ES256', use: 'sig' };
  const state = { nonce: '', sub: opts.sub ?? 'tsudev-user-1' };
  setOidcFetcher(async (url, init) => {
    const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json' } });
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
