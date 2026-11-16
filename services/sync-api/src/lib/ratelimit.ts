import { ApiError } from './errors';

/** Giới hạn cửa sổ cố định trên D1 (đủ cho lưu lượng của gói 0 đồng). */
export async function rateLimit(db: D1Database, key: string, limit: number, windowMs: number): Promise<void> {
  const t = Date.now();
  const windowStart = t - (t % windowMs);
  const row = await db
    .prepare(
      `INSERT INTO rate_limits (key, window_start, count) VALUES (?1, ?2, 1)
       ON CONFLICT(key) DO UPDATE SET
         count = CASE WHEN window_start = ?2 THEN count + 1 ELSE 1 END,
         window_start = ?2
       RETURNING count`,
    )
    .bind(key, windowStart)
    .first<{ count: number }>();
  if ((row?.count ?? 0) > limit) {
    throw new ApiError(429, 'rate_limited', 'Bạn thao tác quá nhanh. Hãy thử lại sau ít phút.');
  }
}
