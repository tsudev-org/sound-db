// QA-11 (phiếu 20261117-06 mục 6): SpectrumAnalyzer lập sẵn bảng dải octave + hệ số trọng số thay vì tính lại mỗi nhịp
// (PR #54). Bảng phải cho kết quả GIỐNG TỪNG BIT vòng đầy đủ của bản Rust tham chiếu - lệch là lỗi, kể cả khi nhỏ hơn
// dung sai của vectors.json. Chi phí đo bằng tool/bench.dart (không kiểm thời gian ở đây: máy CI có tải làm test chập chờn).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:test/test.dart';

/// Bản sao nguyên văn `band_power` của packages/dsp-core (duyệt mọi bin, tính trọng số tại chỗ).
double referenceBandPower(SpectrumAnalyzer s, double loHz, double hiHz, Weighting w) {
  final bin = s.binHz;
  var total = 0.0;
  for (var k = 0; k < s.power.length; k++) {
    final center = k * bin;
    final overlap = (math.min(center + bin / 2, hiHz) - math.max(center - bin / 2, loHz)) / bin;
    if (overlap > 0) {
      final gain = w == Weighting.z ? 1.0 : math.pow(10, analogGainDb(w, math.max(center, 1e-9)) / 10).toDouble();
      total += overlap * s.power[k] * gain;
    }
  }
  return total;
}

Engine noisyEngine(double fs, int fftSize) {
  final rnd = math.Random(7);
  final engine = Engine(sampleRate: fs, fftSize: fftSize);
  final block = Float32List(1024);
  for (var i = 0; i < 40; i++) {
    for (var j = 0; j < block.length; j++) {
      block[j] = (rnd.nextDouble() - 0.5) * 0.2 + 0.1 * math.sin(2 * math.pi * 997 * (i * 1024 + j) / fs);
    }
    engine.push(block);
  }
  engine.analyzeSpectrum();
  return engine;
}

void main() {
  for (final fs in [44100.0, 48000.0]) {
    for (final n in [1024, 8192, 65536]) {
      test('mức dải giống từng bit vòng đầy đủ ($fs Hz, FFT $n)', () {
        final engine = noisyEngine(fs, n);
        for (final fraction in [1, 3]) {
          for (final w in Weighting.values) {
            for (final b in engine.bands(fraction)) {
              expect(
                engine.spectrum.bandPower(b.lowerHz, b.upperHz, w),
                referenceBandPower(engine.spectrum, b.lowerHz, b.upperHz, w),
                reason: '1/$fraction ${b.label} ${w.label}',
              );
            }
          }
        }
      });
    }
  }

  test('phổ dB có trọng số giống từng bit cách tính tại chỗ', () {
    final engine = noisyEngine(48000, 8192);
    final s = engine.spectrum;
    for (final w in Weighting.values) {
      final out = Float64List(s.bins);
      s.spectrumDb(w, out);
      s.spectrumDb(w, out); // lần hai dùng bảng đã lưu
      for (var k = 0; k < s.bins; k++) {
        final g = w == Weighting.z ? 0.0 : analogGainDb(w, k * s.binHz);
        final expected =
            10 * math.log(math.max(s.power[k] * s.enbwBins, 1e-30)) / math.ln10 + s.calibrationOffsetDb + g;
        expect(out[k], expected, reason: '${w.label} bin $k');
      }
    }
  });
}
