declare namespace Cloudflare {
  interface Env {
    DB: D1Database;
    TEST_MIGRATIONS: import('cloudflare:test').D1Migration[];
    PUBLIC_ORIGIN: string;
    OIDC_ISSUER: string;
    OIDC_CLIENT_ID: string;
    SESSION_SECRET: string;
    IP_HASH_SALT: string;
  }
}
