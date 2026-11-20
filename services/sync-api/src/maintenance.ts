import type { Env } from './env';
import { verifyAndPurge } from './pro/purge';

/** CSP riêng cho máy đo trên trình duyệt: cho WebAssembly và micro, chỉ ở trang này. */
export const METER_CSP =
  "default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self'; img-src 'self'; font-src 'self'; " +
  "connect-src 'self'; manifest-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests";

/** Dọn dữ liệu hết hạn (chạy kèm ~1% yêu cầu `/api/*` - tài khoản Cloudflare đã hết Cron miễn phí). */
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
  // Hết Pro quá 90 ngày ⇒ xoá bản sao đám mây, chỉ sau khi kênh trạng thái của tsudev.com xác nhận.
  await verifyAndPurge(env, at);
}

