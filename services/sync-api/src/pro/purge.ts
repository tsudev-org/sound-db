import type { Env } from '../env';
import { GRACE_MS, fetchSubjectStatus, rpConfigured } from './entitlements';

/**
 * Xoá bản sao đám mây vì hết Pro - XOÁ CÓ XÁC MINH (PRODUCT_POLICY 7.4 "Kênh trạng thái", phiếu 20261120-PRO2 2.3).
 * Ứng viên: tài khoản còn bản ghi trên máy chủ mà `pro_until` đã biết + 90 ngày đã qua (kể cả chưa từng có Pro - dữ
 * liệu thử nghiệm trước PRO1). NGAY TRƯỚC khi xoá hỏi lại tsudev.com:
 * - `ok` và `pro_until` + 90 ngày còn ở tương lai ⇒ đã gia hạn (ví dụ trên web, chưa mở app): cập nhật hạn, GIỮ dữ liệu;
 * - `ok` đã quá 90 ngày, hoặc `deleted` ⇒ xoá;
 * - `unknown_subject`, lỗi mạng/HTTP, khung sai ⇒ HOÃN, không hỏi lại trong 24 giờ.
 * Chưa có khoá RP ⇒ không làm gì (hoãn), `MUST NOT` xoá chỉ dựa vào `pro_until` đệm.
 * Chạy kèm ~1% yêu cầu `/api/*` (không còn Cron miễn phí); mỗi lượt tối đa VERIFY_PER_RUN tài khoản.
 */
export const VERIFY_PER_RUN = 20;
export const VERIFY_EVERY_MS = 24 * 3600 * 1000;
const CHUNK = 500;

export interface PurgeResult {
  checked: number;
  kept: number;
  purged: number;
  deferred: number;
}

export async function verifyAndPurge(env: Env, now = Date.now()): Promise<PurgeResult> {
  const out: PurgeResult = { checked: 0, kept: 0, purged: 0, deferred: 0 };
  if (!rpConfigured(env)) return out;
  const rows = await env.DB.prepare(
    `SELECT u.id AS user_id, u.oidc_sub AS sub FROM users u LEFT JOIN entitlements e ON e.user_id = u.id
     WHERE EXISTS (SELECT 1 FROM records r WHERE r.user_id = u.id)
       AND COALESCE(e.pro_until, 0) + ?1 < ?2 AND COALESCE(e.purge_checked_at, 0) < ?3
     LIMIT ?4`,
  )
    .bind(GRACE_MS, now, now - VERIFY_EVERY_MS, VERIFY_PER_RUN)
    .all<{ user_id: string; sub: string }>();
  if (rows.results.length === 0) return out;
  out.checked = rows.results.length;

  const mark = (userId: string) =>
    env.DB.prepare(
      `INSERT INTO entitlements (user_id, purge_checked_at) VALUES (?1, ?2)
       ON CONFLICT(user_id) DO UPDATE SET purge_checked_at = excluded.purge_checked_at`,
    ).bind(userId, now);

  let statuses: Awaited<ReturnType<typeof fetchSubjectStatus>>;
  try {
    statuses = await fetchSubjectStatus(env, rows.results.map((r) => r.sub));
  } catch (e) {
    console.warn('purge_verify_unavailable', e instanceof Error ? e.message.slice(0, 32) : 'error');
    await env.DB.batch(rows.results.map((r) => mark(r.user_id)));
    out.deferred = rows.results.length;
    return out;
  }

  const stmts: D1PreparedStatement[] = [];
  for (const r of rows.results) {
    const st = statuses.get(r.sub);
    if (st?.status === 'ok' && st.proUntil + GRACE_MS > now) {
      stmts.push(
        env.DB.prepare(
          `INSERT INTO entitlements (user_id, pro_until, purge_checked_at) VALUES (?1, ?2, ?3)
           ON CONFLICT(user_id) DO UPDATE SET pro_until = MAX(pro_until, excluded.pro_until), purge_checked_at = excluded.purge_checked_at`,
        ).bind(r.user_id, st.proUntil, now),
      );
      out.kept++;
    } else if (st?.status === 'ok' || st?.status === 'deleted') {
      stmts.push(
        env.DB.prepare(
          'DELETE FROM records WHERE user_id = ?1 AND rowid IN (SELECT rowid FROM records WHERE user_id = ?1 LIMIT ?2)',
        ).bind(r.user_id, CHUNK),
      );
      stmts.push(
        env.DB.prepare('INSERT INTO audit_log (user_id, event, detail, ip_hash, at) VALUES (?, ?, ?, ?, ?)').bind(
          r.user_id,
          'cloud_purged',
          st.status === 'deleted' ? 'tsudev_deleted' : 'pro_expired_90d',
          'system',
          now,
        ),
      );
      // Còn hơn CHUNK bản ghi ⇒ lượt sau chọn lại và hỏi lại tsudev.com trước khi xoá tiếp (vẫn là xoá có xác minh).
      out.purged++;
    } else {
      stmts.push(mark(r.user_id));
      out.deferred++;
    }
  }
  if (stmts.length) await env.DB.batch(stmts);
  return out;
}
