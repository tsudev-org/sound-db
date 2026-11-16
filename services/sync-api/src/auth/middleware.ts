import { getCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';

import type { AppEnv } from '../env';
import { ApiError } from '../lib/errors';
import { sha256Hex } from '../lib/crypto';
import { SESSION_COOKIE, verifyAccessToken } from './tokens';

/**
 * Xác thực mọi đường `/api/v1/*` cần tài khoản:
 * - App: `Authorization: Bearer <access token>`; thiết bị bị thu hồi ⇒ 401 ngay
 *   (kiểm DB mỗi lượt, không chờ token hết hạn).
 * - Web: cookie `__Host-sdb_session` (HttpOnly, Secure, SameSite=Lax). Phương thức
 *   ghi bằng cookie ĐÒI `Origin` đúng gốc + header `X-Sdb-Csrf: 1` (chống CSRF).
 */
export const requireUser = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (header?.startsWith('Bearer ')) {
    const { userId, deviceId } = await verifyAccessToken(c.env, header.slice(7).trim());
    const device = await c.env.DB.prepare('SELECT revoked_at FROM devices WHERE id = ? AND user_id = ?')
      .bind(deviceId, userId)
      .first<{ revoked_at: number | null }>();
    if (!device || device.revoked_at !== null) {
      throw new ApiError(401, 'device_revoked', 'Thiết bị này đã bị đăng xuất khỏi tài khoản.');
    }
    c.set('auth', { userId, deviceId, via: 'bearer' });
    return next();
  }
  const cookie = getCookie(c, SESSION_COOKIE);
  if (!cookie) throw new ApiError(401, 'unauthenticated', 'Bạn cần đăng nhập.');
  const method = c.req.method;
  if (method !== 'GET' && method !== 'HEAD') {
    if (c.req.header('Origin') !== c.env.PUBLIC_ORIGIN || c.req.header('X-Sdb-Csrf') !== '1') {
      throw new ApiError(403, 'csrf', 'Yêu cầu bị chặn vì không đến từ trang Sound Db.');
    }
  }
  const row = await c.env.DB.prepare('SELECT user_id FROM web_sessions WHERE token_hash = ? AND expires_at > ?')
    .bind(await sha256Hex(cookie), Date.now())
    .first<{ user_id: string }>();
  if (!row) throw new ApiError(401, 'unauthenticated', 'Phiên đăng nhập đã hết hạn.');
  c.set('auth', { userId: row.user_id, deviceId: null, via: 'cookie' });
  return next();
});
