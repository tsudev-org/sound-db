import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';

import { authRoutes } from './auth/routes';
import type { AppEnv, Env } from './env';
import { ApiError, errorResponse } from './lib/errors';
import { meRoutes } from './me/routes';
import { syncRoutes } from './sync/routes';

const app = new Hono<AppEnv>();

// Header bảo mật cho mọi phản hồi động (SECURITY_BASELINE.md mục 7.2). Tệp tĩnh
// nhận header từ apps/web/public/_headers.
app.use('*', async (c, next) => {
  await next();
  const h = c.res.headers;
  h.set('Cache-Control', 'no-store');
  h.set('X-Content-Type-Options', 'nosniff');
  h.set('Referrer-Policy', 'no-referrer');
  h.set('X-Frame-Options', 'DENY');
  h.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  h.set('Cross-Origin-Resource-Policy', 'same-origin');
  if (!h.has('Content-Security-Policy')) h.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
});

app.get('/api/v1/health', (c) => c.json({ ok: true, service: 'sound-db', time: new Date().toISOString() }));

app.route('/', authRoutes);
app.route('/', syncRoutes);
app.route('/', meRoutes);

app.notFound((c) => c.json({ code: 'not_found', message: 'Không tìm thấy.' }, 404));

app.onError((err, c) => {
  if (err instanceof ApiError) return errorResponse(c, err);
  if (err instanceof HTTPException) {
    return c.json({ code: 'http_error', message: err.status === 413 ? 'Dữ liệu gửi lên quá lớn.' : 'Yêu cầu không hợp lệ.' }, err.status);
  }
  console.error('unhandled', err);
  return c.json({ code: 'internal', message: 'Máy chủ gặp lỗi. Hãy thử lại sau.' }, 500);
});

/** Dọn dữ liệu hết hạn mỗi ngày (cron trong wrangler.jsonc). */
export async function cleanup(env: Env, at = Date.now()) {
  const day = 24 * 3600 * 1000;
  await env.DB.batch([
    env.DB.prepare('DELETE FROM login_requests WHERE expires_at < ?').bind(at),
    env.DB.prepare('DELETE FROM app_codes WHERE expires_at < ?').bind(at - day),
    env.DB.prepare('DELETE FROM refresh_tokens WHERE expires_at < ? OR (used_at IS NOT NULL AND used_at < ?)').bind(at, at - 30 * day),
    env.DB.prepare('DELETE FROM web_sessions WHERE expires_at < ?').bind(at),
    env.DB.prepare('DELETE FROM rate_limits WHERE window_start < ?').bind(at - day),
    env.DB.prepare('DELETE FROM records WHERE deleted = 1 AND updated_at < ?').bind(at - 180 * day),
    env.DB.prepare('DELETE FROM devices WHERE revoked_at IS NOT NULL AND revoked_at < ?').bind(at - 90 * day),
    env.DB.prepare('DELETE FROM audit_log WHERE at < ?').bind(at - 365 * day),
  ]);
}

export default {
  fetch: app.fetch,
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(cleanup(env));
  },
} satisfies ExportedHandler<Env>;
