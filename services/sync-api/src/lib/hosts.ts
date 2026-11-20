import type { MiddlewareHandler } from 'hono';

import type { AppEnv, Env } from '../env';

/**
 * Nhiều tên miền cho cùng một Worker (ADR-0007): `PUBLIC_ORIGIN` là host CHUẨN (redirect OIDC, CSRF, `iss` của token
 * mới); `ALIAS_ORIGINS` (phân cách bằng dấu phẩy) là các host phụ vẫn phục vụ API cho app đã cài.
 */
export function aliasOrigins(env: Env): string[] {
  return (env.ALIAS_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim().replace(/\/$/, ''))
    .filter((s) => s.length > 0 && s !== env.PUBLIC_ORIGIN);
}

/** `iss` hợp lệ của access token: host chuẩn + host phụ (đảo host chuẩn không đăng xuất app đang chạy). */
export const acceptedIssuers = (env: Env): string[] => [env.PUBLIC_ORIGIN, ...aliasOrigins(env)];

/**
 * `/auth/*` gọi ở host phụ ⇒ chuyển nguyên đường + query về host chuẩn: cookie gắn yêu cầu đăng nhập và cookie phiên
 * web phải nằm cùng host với `redirect_uri` đã đăng ký ở tsudev.com. 307 giữ nguyên phương thức.
 */
export const authOnCanonicalHost: MiddlewareHandler<AppEnv> = async (c, next) => {
  const url = new URL(c.req.url);
  if (url.pathname.startsWith('/auth/') && url.origin !== c.env.PUBLIC_ORIGIN && aliasOrigins(c.env).includes(url.origin)) {
    return c.redirect(`${c.env.PUBLIC_ORIGIN}${url.pathname}${url.search}`, 307);
  }
  return next();
};
