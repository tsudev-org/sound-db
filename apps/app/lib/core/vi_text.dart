/// Chuẩn hoá tiếng Việt cho tìm kiếm (SEARCH_AND_FILTER.md mục 3). MỘT module dùng chung - đừng viết lặp chỗ khác.
///
/// Dart không có `String.normalize` (NFC/NFD) ⇒ bỏ dấu bằng bảng chữ dựng sẵn + xoá dấu tổ hợp U+0300..U+036F. Hai
/// bước đó cho cùng kết quả với chuỗi NFC lẫn NFD, nên không cần chuẩn hoá NFC trước.
library;

const _from = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
const _to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

final Map<int, int> _map = {for (var i = 0; i < _from.length; i++) _from.codeUnitAt(i): _to.codeUnitAt(i)};

final _combining = RegExp('[\u0300-\u036f]');
final _punct = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final _spaces = RegExp(r'\s+');

/// Bỏ dấu tiếng Việt (đ/Đ xử lý riêng vì không tách được qua NFD). Giữ hoa/thường của chữ không dấu.
String viRemoveDiacritics(String input) {
  final s = input.replaceAll(_combining, '');
  final out = StringBuffer();
  for (final c in s.runes) {
    final lower = String.fromCharCode(c).toLowerCase().codeUnitAt(0);
    final base = _map[lower];
    if (base == null) {
      out.writeCharCode(c);
    } else {
      final isUpper = String.fromCharCode(c) != String.fromCharCode(lower);
      out.write(isUpper ? String.fromCharCode(base).toUpperCase() : String.fromCharCode(base));
    }
  }
  return out.toString();
}

/// Chuỗi để so khớp: chữ thường → bỏ dấu → bỏ dấu câu → gộp khoảng trắng.
String viNormalizeText(String input) =>
    viRemoveDiacritics(input.toLowerCase()).replaceAll(_punct, ' ').replaceAll(_spaces, ' ').trim();
