import 'dart:math' as math;

import 'package:sounddb_dsp/src/octave.dart';
import 'package:test/test.dart';

/// QA-02 (21/11/2026): khớp test Rust `octave::tests` - không dải nào dưới 10 Hz bị làm tròn danh định thành 10.
void main() {
  test('dải bắt đầu đúng 10 Hz / 16 Hz, danh định tăng dần, tâm sát danh định', () {
    for (final (fraction, min, first, count) in [(3, 10.0, 10.0, 34), (1, 15.0, 16.0, 11)]) {
      final bs = octaveBands(fraction, min, 20000);
      expect(bs.first.nominalHz, first);
      expect(bs.length, count);
      for (var i = 1; i < bs.length; i++) {
        expect(bs[i].nominalHz, greaterThan(bs[i - 1].nominalHz));
      }
      for (final b in bs) {
        expect((math.log(b.centerHz / b.nominalHz) / math.ln10).abs(), lessThan(0.02));
      }
    }
  });
}
