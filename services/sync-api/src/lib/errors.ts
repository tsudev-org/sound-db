import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

/** Lỗi API: `code` máy đọc được + `message` tiếng Việt hiện thẳng ra giao diện. */
export class ApiError extends Error {
  constructor(
    readonly status: ContentfulStatusCode,
    readonly code: string,
    message: string,
    readonly retryAfter?: number,
  ) {
    super(message);
  }
}

export function errorResponse(c: Context, err: ApiError) {
  // `error` theo hợp đồng chung (PRODUCT_POLICY 7.4: `402 {"error":"pro_required"}`); `code` giữ cho client cũ.
  if (err.retryAfter) c.header('Retry-After', String(err.retryAfter));
  return c.json({ error: err.code, code: err.code, message: err.message }, err.status);
}
