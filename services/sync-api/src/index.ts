import { Hono, type Context } from 'hono';
import { HTTPException } from 'hono/http-exception';

import { authRoutes } from './auth/routes';
import type { AppEnv, Env } from './env';
import { ApiError, errorResponse } from './lib/errors';
import { meRoutes } from './me/routes';
import { syncRoutes } from './sync/routes';
import { METER_CSP, cleanup } from './maintenance';

const app = new Hono<AppEnv>();

// Header bảo mật cho mọi phản hồi động (SECURITY_BASELINE.md mục 7.2). Tệp tĩnh
// nhận header từ apps/web/public/_headers.
app.use('*', async (c, next) => {
  await next();
  if (c.req.path.startsWith('/api/') && Math.random() < 0.01) {
    c.executionCtx.waitUntil(cleanup(c.env).catch((e) => console.error('cleanup', e)));
  }
  const h = c.res.headers;
  if (!h.has('Cache-Control')) h.set('Cache-Control', 'no-store');
  h.set('X-Content-Type-Options', 'nosniff');
  h.set('Referrer-Policy', 'no-referrer');
  h.set('X-Frame-Options', 'DENY');
  h.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  h.set('Cross-Origin-Resource-Policy', 'same-origin');
  if (!h.has('Content-Security-Policy')) h.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
});

// Máy đo trên trình duyệt (vi `/do/`, en `/en/do/`) cần micro + WebAssembly.
const meterPage = async (c: Context<AppEnv>) => {
  if (!c.env.ASSETS) return c.notFound();
  const asset = await c.env.ASSETS.fetch(c.req.raw);
  const res = new Response(asset.body, asset);
  res.headers.set('Content-Security-Policy', METER_CSP);
  res.headers.set(
    'Permissions-Policy',
    'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(self), payment=(), usb=(), interest-cohort=()',
  );
  res.headers.set('Cache-Control', 'public, max-age=300');
  return res;
};
app.get('/do/*', meterPage);
app.get('/en/do/*', meterPage);

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

export default {
  fetch: app.fetch,
} satisfies ExportedHandler<Env>;
