/// Định dạng hiển thị theo ngôn ngữ đang hiển thị (PRODUCT_POLICY mục 1.3). Tiếng Việt theo quy ước tsudev: số
/// thập phân dấu phẩy, ngày `DD/MM/YYYY`, ngày giờ `HH:mm DD/MM/YYYY`. Tiếng Anh: dấu chấm thập phân, ngày ISO
/// `YYYY-MM-DD` (không mơ hồ ngày/tháng), ngày giờ `YYYY-MM-DD HH:mm`. Mọi màn hình đi qua đây.
library;

import '../l10n/l10n.dart';

String _two(int v) => v.toString().padLeft(2, '0');

bool get _vi => activeLanguage == 'vi';

String formatDate(DateTime t) => _vi ? '${_two(t.day)}/${_two(t.month)}/${t.year}' : '${t.year}-${_two(t.month)}-${_two(t.day)}';

String formatDateTime(DateTime t) =>
    _vi ? '${_two(t.hour)}:${_two(t.minute)} ${formatDate(t)}' : '${formatDate(t)} ${_two(t.hour)}:${_two(t.minute)}';

/// Số có [digits] chữ số thập phân (vi: dấu phẩy, en: dấu chấm). NaN/vô cực ⇒ "-".
String formatNumber(double v, {int digits = 1}) {
  if (!v.isFinite) return '-';
  final s = v.toStringAsFixed(digits);
  return _vi ? s.replaceAll('.', ',') : s;
}

String formatDb(double v, {int digits = 1}) => '${formatNumber(v, digits: digits)} dB';

String formatHz(double hz) {
  if (!hz.isFinite || hz <= 0) return '-';
  if (hz >= 1000) return '${formatNumber(hz / 1000, digits: hz >= 10000 ? 2 : 3)} kHz';
  return '${formatNumber(hz, digits: hz >= 100 ? 1 : 2)} Hz';
}

String formatDuration(double seconds) {
  if (!seconds.isFinite || seconds < 0) return '-';
  final total = seconds.floor();
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String formatPercent(double v, {int digits = 1}) => '${formatNumber(v, digits: digits)} %';

/// Đọc số người dùng gõ, chấp nhận cả dấu phẩy lẫn dấu chấm (mọi ngôn ngữ).
double? parseNumber(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
