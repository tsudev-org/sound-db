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
  /**
   * Khoá riêng ES256 (JWK, có `d`, nên có `kid`) cho client assertion `private_key_jwt` gửi tsudev.com (kênh RP +
   * kênh trạng thái, PRODUCT_POLICY 7.4). Khoá công khai đăng ký ở `OAuthClient.rpPublicJwk` của client `sounddb`.
   * Chưa đặt ⇒ không ai được coi là Pro (đẩy dữ liệu bị 402) và đường xoá tự động ở trạng thái HOÃN.
   */
  RP_PRIVATE_JWK?: string;
}

export interface AuthContext {
  userId: string;
  deviceId: string | null;
  via: 'bearer' | 'cookie';
}

export type AppEnv = { Bindings: Env; Variables: { auth: AuthContext } };
