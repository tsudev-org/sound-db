import { Hono } from 'hono';
import { deleteCookie } from 'hono/cookie';
import { z } from 'zod';

import { requireUser } from '../auth/middleware';
import { userJson } from '../auth/routes';
import { SESSION_COOKIE } from '../auth/tokens';
import type { AppEnv } from '../env';
import { audit } from '../lib/audit';
import { ApiError } from '../lib/errors';
import { recordJson, writeRecord } from '../sync/routes';
import { sessionData } from '../sync/schema';

/** Bộ mốc số bản ghi chuẩn (DATA_TABLE.md mục 2 và 8). */
const PAGE_SIZES = [10, 20, 50, 100, 200] as const;

export const meRoutes = new Hono<AppEnv>();
meRoutes.use('/api/v1/me', requireUser);
meRoutes.use('/api/v1/me/*', requireUser);
meRoutes.use('/api/v1/sessions', requireUser);
meRoutes.use('/api/v1/sessions/*', requireUser);

meRoutes.get('/api/v1/me', async (c) => {
  const { userId, deviceId } = c.get('auth');
  const db = c.env.DB;
  const user = await db
    .prepare('SELECT id, email, email_verified, display_name, avatar_url FROM users WHERE id = ?')
    .bind(userId)
    .first<Parameters<typeof userJson>[0]>();
  if (!user) throw new ApiError(401, 'unauthenticated', 'Tài khoản không còn tồn tại.');
  const stats = await db
    .prepare(
      `SELECT
         SUM(CASE WHEN kind = 'session' AND deleted = 0 THEN 1 ELSE 0 END) AS sessions,
         SUM(CASE WHEN kind = 'calibration' AND deleted = 0 THEN 1 ELSE 0 END) AS calibrations,
         COALESCE(SUM(CASE WHEN kind = 'session' AND deleted = 0 THEN json_extract(data, '$.duration_s') END), 0) AS seconds
       FROM records WHERE user_id = ?`,
    )
    .bind(userId)
    .first<{ sessions: number | null; calibrations: number | null; seconds: number }>();
  return c.json({
    ...userJson(user),
    current_device_id: deviceId,
    stats: { sessions: stats?.sessions ?? 0, calibrations: stats?.calibrations ?? 0, measured_seconds: stats?.seconds ?? 0 },
  });
});

meRoutes.get('/api/v1/me/devices', async (c) => {
  const { userId } = c.get('auth');
  const rows = await c.env.DB.prepare(
    `SELECT id, name, platform, created_at, last_seen_at FROM devices
     WHERE user_id = ? AND revoked_at IS NULL ORDER BY last_seen_at DESC LIMIT 200`,
  )
    .bind(userId)
    .all();
  return c.json({ devices: rows.results });
});

meRoutes.delete('/api/v1/me/devices/:id', async (c) => {
  const { userId } = c.get('auth');
  const id = c.req.param('id');
  const t = Date.now();
  const res = await c.env.DB.prepare('UPDATE devices SET revoked_at = ? WHERE id = ? AND user_id = ? AND revoked_at IS NULL')
    .bind(t, id, userId)
    .run();
  if (res.meta.changes !== 1) throw new ApiError(404, 'not_found', 'Không tìm thấy thiết bị.');
  await c.env.DB.prepare('DELETE FROM refresh_tokens WHERE device_id = ?').bind(id).run();
  await audit(c, userId, 'device_revoked', id);
  return c.body(null, 204);
});

meRoutes.get('/api/v1/me/activity', async (c) => {
  const { userId } = c.get('auth');
  const rows = await c.env.DB.prepare('SELECT event, detail, at FROM audit_log WHERE user_id = ? ORDER BY at DESC LIMIT 50')
    .bind(userId)
    .all();
  return c.json({ events: rows.results });
});

/** Tải toàn bộ dữ liệu (quyền mang dữ liệu đi). */
meRoutes.get('/api/v1/me/export', async (c) => {
  const { userId } = c.get('auth');
  const rows = await c.env.DB.prepare(
    'SELECT kind, id, rev, updated_at, deleted, data FROM records WHERE user_id = ? AND deleted = 0 ORDER BY rev',
  )
    .bind(userId)
    .all<{ kind: 'session' | 'calibration'; id: string; rev: number; updated_at: number; deleted: number; data: string }>();
  c.header('Content-Disposition', 'attachment; filename="sound-db-du-lieu.json"');
  return c.json({ exported_at: new Date().toISOString(), records: rows.results.map(recordJson) });
});

/** Xóa toàn bộ dữ liệu Sound Db của tài khoản (danh tính tsudev không bị ảnh hưởng). */
meRoutes.delete('/api/v1/me', async (c) => {
  const { userId } = c.get('auth');
  if (c.req.header('X-Sdb-Confirm') !== 'xoa-vinh-vien') {
    throw new ApiError(400, 'confirm_required', 'Cần xác nhận xóa vĩnh viễn.');
  }
  await c.env.DB.batch([
    c.env.DB.prepare('DELETE FROM records WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM refresh_tokens WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM web_sessions WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM devices WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM app_codes WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM audit_log WHERE user_id = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(userId),
  ]);
  deleteCookie(c, SESSION_COOKIE, { path: '/', secure: true });
  return c.body(null, 204);
});

meRoutes.get('/api/v1/sessions', async (c) => {
  const { userId } = c.get('auth');
  const q = z
    .object({
      page: z.coerce.number().int().min(1).max(100000).default(1),
      page_size: z.coerce
        .number()
        .int()
        .refine((v) => (PAGE_SIZES as readonly number[]).includes(v))
        .catch(10),
      q: z.string().trim().max(100).optional(),
    })
    .safeParse(c.req.query());
  if (!q.success) throw new ApiError(400, 'invalid_request', 'Tham số không hợp lệ.');
  const { page, page_size: size } = q.data;
  const term = q.data.q ? `%${q.data.q.replace(/[\\%_]/g, (m) => `\\${m}`)}%` : null;
  const where = `user_id = ?1 AND kind = 'session' AND deleted = 0${term ? " AND json_extract(data, '$.label') LIKE ?2 ESCAPE '\\'" : ''}`;
  const binds = term ? [userId, term] : [userId];
  const total = await c.env.DB.prepare(`SELECT COUNT(*) AS n FROM records WHERE ${where}`)
    .bind(...binds)
    .first<{ n: number }>();
  const rows = await c.env.DB.prepare(
    `SELECT id, rev, updated_at,
       json_extract(data, '$.label') AS label,
       json_extract(data, '$.started_at') AS started_at,
       json_extract(data, '$.duration_s') AS duration_s,
       json_extract(data, '$.summary.laeq') AS laeq,
       json_extract(data, '$.summary.lafmax') AS lafmax,
       json_extract(data, '$.summary.lcpeak') AS lcpeak,
       json_extract(data, '$.device_model') AS device_model
     FROM records WHERE ${where}
     ORDER BY json_extract(data, '$.started_at') DESC LIMIT ${size} OFFSET ${(page - 1) * size}`,
  )
    .bind(...binds)
    .all();
  return c.json({ items: rows.results, total: total?.n ?? 0, page, page_size: size });
});

meRoutes.get('/api/v1/sessions/:id', async (c) => {
  const { userId } = c.get('auth');
  const row = await c.env.DB.prepare(
    "SELECT kind, id, rev, updated_at, deleted, data FROM records WHERE user_id = ? AND kind = 'session' AND id = ? AND deleted = 0",
  )
    .bind(userId, c.req.param('id'))
    .first<{ kind: 'session'; id: string; rev: number; updated_at: number; deleted: number; data: string }>();
  if (!row) throw new ApiError(404, 'not_found', 'Không tìm thấy phiên đo.');
  return c.json(recordJson(row));
});

meRoutes.patch('/api/v1/sessions/:id', async (c) => {
  const { userId } = c.get('auth');
  const body = z
    .object({ label: z.string().trim().min(1).max(120).optional(), note: z.string().max(2000).optional() })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw new ApiError(400, 'invalid_request', 'Dữ liệu sửa không hợp lệ.');
  const row = await c.env.DB.prepare(
    "SELECT data FROM records WHERE user_id = ? AND kind = 'session' AND id = ? AND deleted = 0",
  )
    .bind(userId, c.req.param('id'))
    .first<{ data: string }>();
  if (!row) throw new ApiError(404, 'not_found', 'Không tìm thấy phiên đo.');
  const data = sessionData.parse({ ...JSON.parse(row.data), ...body.data });
  const rev = await writeRecord(c.env.DB, userId, null, 'session', c.req.param('id'), Date.now(), false, data);
  return c.json({ rev });
});

meRoutes.delete('/api/v1/sessions/:id', async (c) => {
  const { userId } = c.get('auth');
  const exists = await c.env.DB.prepare(
    "SELECT 1 AS ok FROM records WHERE user_id = ? AND kind = 'session' AND id = ? AND deleted = 0",
  )
    .bind(userId, c.req.param('id'))
    .first();
  if (!exists) throw new ApiError(404, 'not_found', 'Không tìm thấy phiên đo.');
  await writeRecord(c.env.DB, userId, null, 'session', c.req.param('id'), Date.now(), true, {});
  return c.body(null, 204);
});
