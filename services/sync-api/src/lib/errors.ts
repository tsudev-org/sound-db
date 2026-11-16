import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

/** Lỗi API: `code` máy đọc được + `message` tiếng Việt hiện thẳng ra giao diện. */
export class ApiError extends Error {
  constructor(
    readonly status: ContentfulStatusCode,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export function errorResponse(c: Context, err: ApiError) {
  return c.json({ code: err.code, message: err.message }, err.status);
}
