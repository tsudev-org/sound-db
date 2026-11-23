import type { Lang } from '../i18n';

/** Số có một (hoặc `so` ) chữ số thập phân theo ngôn ngữ hiển thị: vi dùng dấu phẩy, en dùng dấu chấm. */
export function dinhDangSo(lang: Lang, n: number, so = 1): string {
  return new Intl.NumberFormat(lang === 'vi' ? 'vi-VN' : 'en-US', {
    minimumFractionDigits: so,
    maximumFractionDigits: so,
  }).format(n);
}
