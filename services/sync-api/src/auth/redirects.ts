/**
 * Danh sách cho phép đích quay về của APP (so khớp tuyệt đối, không tiền tố):
 * - `com.tsudev.sounddb:/auth/callback` - Android, iOS (nhận qua app_links).
 * - `http://127.0.0.1:<cổng>/callback` - Windows, macOS, Linux (RFC 8252 mục 7.3: cổng
 *   vòng lặp do hệ điều hành cấp nên được tự do, mọi phần khác khớp tuyệt đối).
 * Phải khớp `apps/app/lib/sync/api_config.dart`.
 */
export const APP_SCHEME_REDIRECT = 'com.tsudev.sounddb:/auth/callback';

export function isAllowedAppRedirect(value: string): boolean {
  if (value === APP_SCHEME_REDIRECT) return true;
  const m = /^http:\/\/127\.0\.0\.1:(\d{1,5})\/callback$/.exec(value);
  if (!m) return false;
  const port = Number(m[1]);
  return port >= 1024 && port <= 65535;
}

/** Đích nội bộ sau đăng nhập web: chỉ đường dẫn tương đối cùng gốc (chống open redirect). */
export function safeReturnTo(value: string | undefined | null): string {
  if (!value || !value.startsWith('/') || value.startsWith('//') || value.includes('\\') || /[\r\n]/.test(value)) {
    return '/bang-dieu-khien/';
  }
  return value.length > 256 ? '/bang-dieu-khien/' : value;
}
