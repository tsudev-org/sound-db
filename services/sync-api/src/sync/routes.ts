import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { z } from 'zod';

import { requireUser } from '../auth/middleware';
import type { AppEnv } from '../env';
import { ApiError } from '../lib/errors';
import { rateLimit } from '../lib/ratelimit';
import { requirePro } from '../pro/entitlements';
import { MAX_RECORD_BYTES, pushBody, validateData, type Kind } from './schema';

interface RecordRow {
  kind: Kind;
  id: string;
  rev: number;
  updated_at: number;
  deleted: number;
  data: string;
}

export function recordJson(r: RecordRow) {
  return { kind: r.kind, id: r.id, rev: r.rev, updated_at: r.updated_at, deleted: r.deleted === 1, data: JSON.parse(r.data) };
}

/** Ghi một bản ghi với rev mới (dùng chung cho đồng bộ và sửa từ web). */
export async function writeRecord(
  db: D1Database,
  userId: string,
  deviceId: string | null,
  kind: Kind,
  id: string,
  updatedAt: number,
  deleted: boolean,
  data: Record<string, unknown>,
): Promise<number> {
  const rev = await db.prepare('UPDATE users SET rev = rev + 1 WHERE id = ? RETURNING rev').bind(userId).first<{ rev: number }>();
  if (!rev) throw new ApiError(401, 'unauthenticated', 'Tài khoản không còn tồn tại.');
  await db
    .prepare(
      `INSERT INTO records (user_id, kind, id, rev, updated_at, deleted, data, device_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(user_id, kind, id) DO UPDATE SET rev = excluded.rev, updated_at = excluded.updated_at,
         deleted = excluded.deleted, data = excluded.data, device_id = excluded.device_id`,
    )
    .bind(userId, kind, id, rev.rev, updatedAt, deleted ? 1 : 0, JSON.stringify(data), deviceId)
    .run();
  return rev.rev;
}

export const syncRoutes = new Hono<AppEnv>();

syncRoutes.use('/api/v1/sync/*', requireUser);

syncRoutes.post('/api/v1/sync/push', bodyLimit({ maxSize: 4 * 1024 * 1024 }), async (c) => {
  const { userId, deviceId } = c.get('auth');
  await rateLimit(c.env.DB, `push:${userId}`, 120, 60_000);
  // Đẩy lên đám mây là Pro (PRODUCT_POLICY 7.1 N3/N4): kiểm ở MÁY CHỦ trước khi đọc thân yêu cầu.
  await requirePro(c.env, userId);
  const parsed = pushBody.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) throw new ApiError(400, 'invalid_request', 'Gói đồng bộ không hợp lệ.');
  const maxFuture = Date.now() + 24 * 3600 * 1000;
  const results = [];
  for (const ch of parsed.data.changes) {
    let data: Record<string, unknown>;
    try {
      data = validateData(ch.kind, ch.deleted, ch.data);
    } catch {
      results.push({ kind: ch.kind, id: ch.id, status: 'rejected', reason: 'invalid_data' });
      continue;
    }
    if (ch.updated_at > maxFuture || JSON.stringify(data).length > MAX_RECORD_BYTES) {
      results.push({ kind: ch.kind, id: ch.id, status: 'rejected', reason: ch.updated_at > maxFuture ? 'clock' : 'too_large' });
      continue;
    }
    const existing = await c.env.DB.prepare(
      'SELECT kind, id, rev, updated_at, deleted, data FROM records WHERE user_id = ? AND kind = ? AND id = ?',
    )
      .bind(userId, ch.kind, ch.id)
      .first<RecordRow>();
    // Ghi sau thắng theo updated_at; bằng nhau thì bản máy chủ giữ nguyên.
    if (existing && existing.updated_at >= ch.updated_at) {
      results.push({ kind: ch.kind, id: ch.id, status: 'stale', record: recordJson(existing) });
      continue;
    }
    const rev = await writeRecord(c.env.DB, userId, deviceId, ch.kind, ch.id, ch.updated_at, ch.deleted, data);
    results.push({ kind: ch.kind, id: ch.id, status: 'applied', rev });
  }
  return c.json({ results });
});

// Kéo không cần Pro: hết Pro vẫn kéo/xuất được bản sao đám mây cho tới khi bị xoá có xác minh (7.2, 90 ngày).
syncRoutes.get('/api/v1/sync/pull', async (c) => {
  const { userId } = c.get('auth');
  const q = z
    .object({ since: z.coerce.number().int().min(0).default(0), limit: z.coerce.number().int().min(1).max(500).default(200) })
    .safeParse(c.req.query());
  if (!q.success) throw new ApiError(400, 'invalid_request', 'Tham số không hợp lệ.');
  const rows = await c.env.DB.prepare(
    'SELECT kind, id, rev, updated_at, deleted, data FROM records WHERE user_id = ? AND rev > ? ORDER BY rev LIMIT ?',
  )
    .bind(userId, q.data.since, q.data.limit + 1)
    .all<RecordRow>();
  const page = rows.results.slice(0, q.data.limit);
  return c.json({
    changes: page.map(recordJson),
    cursor: page.length ? page[page.length - 1]!.rev : q.data.since,
    has_more: rows.results.length > q.data.limit,
  });
});
