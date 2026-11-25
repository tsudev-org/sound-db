// QA-11 bước 4 (phiếu 20261125-10 P2): lọc trọng số theo khối + FFT thực.
// - Lọc theo khối phải TRÙNG BIT bản từng mẫu (cùng phép tính, cùng thứ tự) - bản Rust tham chiếu không đổi.
// - FFT thực khác FFT phức chỉ ở sai số làm tròn; dung sai so với Rust vẫn do conformance_test.dart kiểm.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:test/test.dart';

Float32List noise(int n, int seed, double fs) {
  final rnd = math.Random(seed);
  return Float32List.fromList([
    for (var i = 0; i < n; i++) (rnd.nextDouble() - 0.5) * 0.3 + 0.2 * math.sin(2 * math.pi * 1234.5 * i / fs),
  ]);
}

/// Bản từng mẫu (trước QA-11 bước 4) của các bộ tách sóng F/S/I, tổng bình phương và đỉnh.
class RefDetector {
  RefDetector(Weighting w, this.fs) : filter = WeightingFilter(w, fs);
  final WeightingFilter filter;
  final double fs;
  double fast = 0, slow = 0, impulse = 0, sumSq = 0, peakAbs = 0;

  void push(Float32List block) {
    double a(double tau) => 1 - math.exp(-1 / (tau * fs));
    final aF = a(tauFast), aS = a(tauSlow), aR = a(tauImpulseRise), aD = a(tauImpulseDecay);
    for (var i = 0; i < block.length; i++) {
      final y = filter.process(block[i]);
      final sq = y * y;
      fast += aF * (sq - fast);
      slow += aS * (sq - slow);
      impulse += (sq > impulse ? aR : aD) * (sq - impulse);
      sumSq += sq;
      final abs = y.abs();
      if (abs > peakAbs) peakAbs = abs;
    }
  }
}

double db(double ms) => 10 * math.log(math.max(ms, 1e-20)) / math.ln10;

void main() {
  group('RealFft', () {
    for (final n in [4, 8, 64, 1024, 8192, 65536]) {
      test('thuận khớp Fft phức, ngược trả lại N·x (N = $n)', () {
        final rnd = math.Random(n);
        final x = Float64List.fromList([for (var i = 0; i < n; i++) rnd.nextDouble() * 2 - 1]);
        final re = Float64List.fromList(x), im = Float64List(n);
        Fft(n).transform(re, im);
        final rf = RealFft(n);
        final hr = Float64List(rf.bins), hi = Float64List(rf.bins);
        rf.forward(x, hr, hi);
        final tol = 1e-12 * n;
        for (var k = 0; k < rf.bins; k++) {
          expect(hr[k], closeTo(re[k], tol), reason: 're[$k]');
          expect(hi[k], closeTo(im[k], tol), reason: 'im[$k]');
        }
        final back = Float64List(n);
        rf.inverse(hr, hi, back);
        for (var i = 0; i < n; i++) {
          expect(back[i] / n, closeTo(x[i], 1e-12), reason: 'x[$i]');
        }
      });
    }
  });

  group('lọc theo khối trùng bit bản từng mẫu', () {
    for (final fs in [44100.0, 48000.0]) {
      test('WeightingFilter.processBlock (fs = $fs)', () {
        final input = noise(5000, 3, fs);
        for (final w in Weighting.values) {
          final a = WeightingFilter(w, fs), b = WeightingFilter(w, fs);
          final out = Float64List(input.length);
          b.processBlock(input, 0, input.length, out);
          for (var i = 0; i < input.length; i++) {
            expect(out[i], a.process(input[i]), reason: '$w mẫu $i');
          }
        }
      });

      test('SoundLevelMeter với mọi cỡ khối (fs = $fs)', () {
        final input = noise((fs * 1.7).round(), 11, fs);
        final ref = [for (final w in Weighting.values) RefDetector(w, fs)..push(input)];
        List<double>? first;
        for (final size in [1, 7, 480, 960, 1023, 4096, input.length]) {
          final meter = SoundLevelMeter(fs, 0);
          for (var off = 0; off < input.length; off += size) {
            meter.process(Float32List.sublistView(input, off, math.min(off + size, input.length)));
          }
          final s = meter.snapshot();
          for (final w in Weighting.values) {
            final r = ref[w.index];
            expect(meter.weightedSumSquares(w), r.sumSq, reason: 'khối $size $w sumSq');
            expect(s.instant[w.index], [db(r.fast), db(r.slow), db(r.impulse)], reason: 'khối $size $w F/S/I');
            expect(s.peak[w.index], db(r.peakAbs * r.peakAbs), reason: 'khối $size $w đỉnh');
          }
          final flat = s.toFlat();
          if (first == null) {
            first = flat;
          } else {
            // Thống kê (Max/Min, phân vị, liều) cập nhật đúng các mốc 10 ms như bản từng mẫu.
            for (var i = 0; i < flat.length; i++) {
              expect(
                flat[i].isNaN ? 'NaN' : flat[i],
                first[i].isNaN ? 'NaN' : first[i],
                reason: 'khối $size chỉ số $i',
              );
            }
          }
        }
      });
    }
  });

  test('phân vị một lượt + mức tức thời khớp cách tính từng mức', () {
    final meter = SoundLevelMeter(48000, 94);
    expect(meter.snapshot().percentiles.every((v) => v.isNaN), isTrue);
    final input = noise(48000 * 3, 9, 48000);
    for (var i = 0; i < input.length; i += 4800) {
      // Biên độ đổi theo khối để histogram trải rộng.
      final block = Float32List.fromList([for (final v in input.sublist(i, i + 4800)) v * (1 + i % 7)]);
      meter.process(block);
      final s = meter.snapshot();
      expect(s.percentiles, [for (final p in percentileLevels) meter.percentile(p)]);
      for (final w in Weighting.values) {
        for (final t in TimeWeighting.values) {
          expect(meter.instantDb(w, t), s.level(w, t));
        }
      }
    }
  });

  test('vòng đệm Engine giữ đúng mẫu mới nhất với mọi cỡ khối (kể cả > vòng đệm)', () {
    final input = noise(Engine.ringSize * 2 + 777, 5, 48000);
    for (final size in [1000, Engine.ringSize - 1, Engine.ringSize + 3, input.length]) {
      final engine = Engine(sampleRate: 48000);
      for (var off = 0; off < input.length; off += size) {
        engine.push(Float32List.sublistView(input, off, math.min(off + size, input.length)));
      }
      final tail = engine.latest(8192);
      expect(tail, input.sublist(input.length - 8192), reason: 'khối $size');
    }
  });
}
