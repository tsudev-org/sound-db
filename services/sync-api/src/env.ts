export interface Env {
  DB: D1Database;
  ASSETS?: Fetcher;
  PUBLIC_ORIGIN: string;
  OIDC_ISSUER: string;
  OIDC_CLIENT_ID: string;
  /** HMAC ký access token của app. >= 32 byte ngẫu nhiên, wrangler secret. */
  SESSION_SECRET: string;
  /** Muối băm IP trong nhật ký, wrangler secret. */
  IP_HASH_SALT: string;
}

export interface AuthContext {
  userId: string;
  deviceId: string | null;
  via: 'bearer' | 'cookie';
}

export type AppEnv = { Bindings: Env; Variables: { auth: AuthContext } };
