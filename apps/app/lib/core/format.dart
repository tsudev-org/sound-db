/// Định dạng hiển thị theo quy ước tsudev: số thập phân dấu phẩy kiểu Việt,
/// ngày `DD/MM/YYYY`, ngày giờ `HH:mm DD/MM/YYYY`. Mọi màn hình đi qua đây.
library;

String _two(int v) => v.toString().padLeft(2, '0');

String formatDate(DateTime t) => '${_two(t.day)}/${_two(t.month)}/${t.year}';

String formatDateTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)} ${formatDate(t)}';

/// Số có [digits] chữ số thập phân, dấu phẩy thập phân. NaN/vô cực ⇒ "-".
String formatNumber(double v, {int digits = 1}) {
  if (!v.isFinite) return '-';
  return v.toStringAsFixed(digits).replaceAll('.', ',');
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

/// Đọc số người dùng gõ, chấp nhận cả dấu phẩy lẫn dấu chấm.
double? parseNumber(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
