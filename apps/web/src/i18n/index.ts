// Ngôn ngữ của website (PRODUCT_POLICY mục 1): tiếng Việt ở gốc `/`, tiếng Anh ở `/en/`. Cùng đường dẫn con
// (`/do/` ↔ `/en/do/`) để bộ chọn ngôn ngữ và `public/lang.js` đổi qua lại được.
import { en } from './en';
import { vi, type Dict } from './vi';

export type Lang = 'vi' | 'en';
export const LANGS: Lang[] = ['vi', 'en'];
export const DICT: Record<Lang, Dict> = { vi, en };
export const t = (lang: Lang): Dict => DICT[lang];

/** Đường dẫn của trang `duong` (dạng tiếng Việt, ví dụ `/do/`) trong ngôn ngữ `lang`. */
export const duongDan = (lang: Lang, duong: string) => (lang === 'en' ? `/en${duong}` : duong);

/** Ngôn ngữ của một đường dẫn đang mở. */
export const langCua = (path: string): Lang => (path === '/en' || path.startsWith('/en/') ? 'en' : 'vi');

/** Thay `{x}`, `{a}`... trong chuỗi dịch. */
export const dien = (mau: string, gt: Record<string, string | number>) =>
  mau.replace(/\{(\w+)\}/g, (m, k: string) => (k in gt ? String(gt[k]) : m));
