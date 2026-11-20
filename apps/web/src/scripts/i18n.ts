// Ngôn ngữ của trang đang mở (thẻ <html lang>) cho script phía trình duyệt.
import { DICT, dien, duongDan, type Lang } from '../i18n';

export const lang: Lang = document.documentElement.lang === 'en' ? 'en' : 'vi';
export const d = DICT[lang];
export const den = (p: string) => duongDan(lang, p);
export { dien };

/** Số thập phân theo ngôn ngữ hiển thị (vi: dấu phẩy - DESIGN_SYSTEM mục 4; en: dấu chấm). */
export const thapPhan = (v: number, chuSo: number) => {
  const s = v.toFixed(chuSo);
  return lang === 'vi' ? s.replace('.', ',') : s;
};
const hai = (n: number) => String(n).padStart(2, '0');
/** Ngày theo ngôn ngữ hiển thị: vi dd/MM/yyyy, en yyyy-MM-dd (không mơ hồ tháng/ngày). */
export const ngay = (x: Date) =>
  lang === 'vi' ? `${hai(x.getDate())}/${hai(x.getMonth() + 1)}/${x.getFullYear()}` : `${x.getFullYear()}-${hai(x.getMonth() + 1)}-${hai(x.getDate())}`;
export const ngayGio = (x: Date) => (lang === 'vi' ? `${hai(x.getHours())}:${hai(x.getMinutes())} ${ngay(x)}` : `${ngay(x)} ${hai(x.getHours())}:${hai(x.getMinutes())}`);
