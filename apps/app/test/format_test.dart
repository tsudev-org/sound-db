import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/core/format.dart';

void main() {
  test('ngày theo DD/MM/YYYY, giữ số 0 đầu', () {
    final t = DateTime(2026, 8, 5, 7, 3);
    expect(formatDate(t), '05/08/2026');
    expect(formatDateTime(t), '07:03 05/08/2026');
  });

  test('số thập phân dấu phẩy, NaN thành gạch', () {
    expect(formatNumber(72.44), '72,4');
    expect(formatDb(94), '94,0 dB');
    expect(formatNumber(double.nan), '-');
    expect(formatHz(1000), '1,000 kHz');
    expect(formatHz(440), '440,0 Hz');
    expect(formatDuration(3725), '1:02:05');
  });

  test('đọc số chấp nhận dấu phẩy', () {
    expect(parseNumber(' 118,5 '), 118.5);
    expect(parseNumber('x'), isNull);
  });
}
