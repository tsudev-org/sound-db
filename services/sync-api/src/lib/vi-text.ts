// Chuẩn hoá tiếng Việt cho tìm kiếm (SEARCH_AND_FILTER.md mục 3.2). MỘT module dùng chung phía máy chủ; bản Dart của
// app là apps/app/lib/core/vi_text.dart - hai bản phải cho cùng kết quả (test cùng ca ở hai nơi).

/** Bỏ dấu tiếng Việt. Xử lý riêng đ/Đ vì NFD không tách được hai ký tự này. */
export function viRemoveDiacritics(input: string): string {
  return input
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D');
}

/** Chuẩn hoá để so khớp: NFC → chữ thường → bỏ dấu → bỏ dấu câu → gộp khoảng trắng. */
export function viNormalizeText(input: string): string {
  return viRemoveDiacritics(input.normalize('NFC').toLowerCase())
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Trường tìm kiếm của một phiên đo: nhãn + ghi chú + thiết bị. */
export function sessionSearchNorm(data: Record<string, unknown>): string {
  return viNormalizeText([data.label, data.note, data.device_model].filter((v) => typeof v === 'string').join(' '));
}

export const MIN_QUERY_LENGTH = 2;
