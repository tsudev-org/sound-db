import 'dart:math' as math;
import 'dart:typed_data';

import 'fft.dart';
import 'weighting.dart';

enum WindowKind {
  rectangular('Chữ nhật'),
  hann('Hann'),
  hamming('Hamming'),
  blackmanHarris('Blackman-Harris'),
  flatTop('Đỉnh phẳng');

  const WindowKind(this.label);
  final String label;

  Float64List coefficients(int size) {
    final List<double> a;
    switch (this) {
      case WindowKind.rectangular:
        return Float64List(size)..fillRange(0, size, 1);
      case WindowKind.hann:
        a = const [0.5, 0.5];
      case WindowKind.hamming:
        a = const [0.54, 0.46];
      case WindowKind.blackmanHarris:
        a = const [0.35875, 0.48829, 0.14128, 0.01168];
      case WindowKind.flatTop:
        a = const [0.21557895, 0.41663158, 0.277263158, 0.083578947, 0.006947368];
    }
    final out = Float64List(size);
    for (var i = 0; i < size; i++) {
      final x = 2 * math.pi * i / size;
      var acc = 0.0;
      for (var k = 0; k < a.length; k++) {
        acc += (k.isEven ? 1 : -1) * a[k] * math.cos(k * x);
      }
      out[i] = acc;
    }
    return out;
  }

  int get lobeHalfWidth => switch (this) {
        WindowKind.rectangular => 1,
        WindowKind.hann || WindowKind.hamming => 4,
        WindowKind.blackmanHarris => 6,
        WindowKind.flatTop => 7,
      };
}

enum Averaging { none, exponential, linear }

class PeakEstimate {
  const PeakEstimate(this.frequencyHz, this.levelDb, this.bin);
  final double frequencyHz;
  final double levelDb;
  final int bin;
}

/// Bộ phân tích phổ - bản port của `SpectrumAnalyzer` (Rust).
class SpectrumAnalyzer {
  SpectrumAnalyzer(this.size, this.sampleRate, this.windowKind, this.calibrationOffsetDb)
      : assert(size >= 64 && size <= 65536 && (size & (size - 1)) == 0),
        _fft = Fft(size),
        _window = windowKind.coefficients(size),
        _re = Float64List(size),
        _im = Float64List(size),
        power = Float64List(size ~/ 2 + 1),
        peakHold = Float64List(size ~/ 2 + 1) {
    for (final w in _window) {
      _windowSum += w;
      _windowSqSum += w * w;
    }
  }

  final int size;
  final double sampleRate;
  final WindowKind windowKind;
  double calibrationOffsetDb;
  Averaging averaging = Averaging.exponential;
  double expAlpha = 0.3;

  final Fft _fft;
  final Float64List _window;
  final Float64List _re, _im;
  double _windowSum = 0, _windowSqSum = 0;
  int _frames = 0;

  // QA-11: bin và trọng số là hằng với một bộ phân tích ⇒ lập bảng một lần. Giữ ĐÚNG biểu thức và thứ tự cộng của bản
  // gốc (kết quả trùng bit, vectors.json không đổi). Trước: mỗi nhịp quét 78 dải × 4097 bin + pow/log từng bin.
  final Map<Weighting, Float64List> _gainDbTable = {};
  final Map<Weighting, Float64List> _gainLinTable = {};
  final Map<(double, double), _BandPlan> _bandPlans = {};

  Float64List _gainDb(Weighting w) => _gainDbTable.putIfAbsent(w, () {
        final bin = binHz;
        final t = Float64List(bins);
        for (var k = 0; k < t.length; k++) {
          t[k] = w == Weighting.z ? 0.0 : analogGainDb(w, k * bin);
        }
        return t;
      });

  Float64List _gainLin(Weighting w) => _gainLinTable.putIfAbsent(w, () {
        final bin = binHz;
        final t = Float64List(bins);
        for (var k = 0; k < t.length; k++) {
          t[k] = w == Weighting.z ? 1.0 : math.pow(10, analogGainDb(w, math.max(k * bin, 1e-9)) / 10).toDouble();
        }
        return t;
      });

  _BandPlan _plan(double loHz, double hiHz) {
    final key = (loHz, hiHz);
    final cached = _bandPlans[key];
    if (cached != null) return cached;
    if (_bandPlans.length >= 256) _bandPlans.clear();
    final bin = binHz;
    final ks = <int>[];
    final overlaps = <double>[];
    for (var k = 0; k < bins; k++) {
      final center = k * bin;
      final overlap = (math.min(center + bin / 2, hiHz) - math.max(center - bin / 2, loHz)) / bin;
      if (overlap > 0) {
        ks.add(k);
        overlaps.add(overlap);
      }
    }
    return _bandPlans[key] = _BandPlan(Int32List.fromList(ks), Float64List.fromList(overlaps));
  }

  /// Công suất (mean-square) mỗi bin, đã trung bình.
  final Float64List power;
  final Float64List peakHold;

  int get bins => size ~/ 2 + 1;
  double get binHz => sampleRate / size;
  double get enbwBins => size * _windowSqSum / (_windowSum * _windowSum);

  void reset() {
    power.fillRange(0, power.length, 0);
    peakHold.fillRange(0, peakHold.length, 0);
    _frames = 0;
  }

  void analyze(Float32List frame) {
    assert(frame.length == size);
    // Bỏ thành phần một chiều (DC) - xem bản Rust.
    var mean = 0.0;
    for (var i = 0; i < size; i++) {
      mean += frame[i];
    }
    mean /= size;
    for (var i = 0; i < size; i++) {
      _re[i] = (frame[i] - mean) * _window[i];
      _im[i] = 0;
    }
    _fft.transform(_re, _im);
    final norm = size * _windowSqSum;
    final last = size ~/ 2;
    _frames++;
    final double alpha = switch (averaging) {
      Averaging.none => 1,
      Averaging.exponential => _frames == 1 ? 1 : expAlpha.clamp(1e-4, 1),
      Averaging.linear => 1 / _frames,
    };
    for (var k = 0; k <= last; k++) {
      final oneSided = (k == 0 || k == last) ? 1.0 : 2.0;
      final p = oneSided * (_re[k] * _re[k] + _im[k] * _im[k]) / norm;
      power[k] += alpha * (p - power[k]);
      if (power[k] > peakHold[k]) peakHold[k] = power[k];
    }
  }

  double _amplitudeDb(double p) => 10 * math.log(math.max(p * enbwBins, 1e-30)) / math.ln10 + calibrationOffsetDb;

  /// Phổ dB (thang biên độ: một sin đọc ra đúng mức RMS của nó).
  void spectrumDb(Weighting weighting, Float64List out, {bool fromPeakHold = false}) {
    final source = fromPeakHold ? peakHold : power;
    final gain = _gainDb(weighting);
    for (var k = 0; k < bins; k++) {
      out[k] = _amplitudeDb(source[k]) + gain[k];
    }
  }

  double bandPower(double loHz, double hiHz, Weighting weighting) {
    final plan = _plan(loHz, hiHz);
    final gain = _gainLin(weighting);
    final ks = plan.bins, overlaps = plan.overlaps;
    var total = 0.0;
    for (var j = 0; j < ks.length; j++) {
      final k = ks[j];
      total += overlaps[j] * power[k] * gain[k];
    }
    return total;
  }

  double bandLevelDb(double loHz, double hiHz, Weighting weighting) =>
      10 * math.log(math.max(bandPower(loHz, hiHz, weighting), 1e-30)) / math.ln10 + calibrationOffsetDb;

  /// Đỉnh mạnh nhất: tần số = trọng tâm công suất, mức = tổng Parseval quanh đỉnh.
  PeakEstimate? dominantPeak(double minHz, double maxHz) {
    final bin = binHz;
    final last = power.length - 1;
    final lo = math.max(1, (minHz / bin).ceil());
    final hi = math.min(last - 1, (maxHz / bin).floor());
    if (lo > hi) return null;
    var best = lo;
    for (var k = lo + 1; k <= hi; k++) {
      if (power[k] > power[best]) best = k;
    }
    if (power[best] <= 0) return null;
    if (windowKind == WindowKind.rectangular) {
      final a = math.log(math.max(power[best - 1], 1e-300));
      final b = math.log(power[best]);
      final c = math.log(math.max(power[best + 1], 1e-300));
      final denom = a - 2 * b + c;
      final delta = denom.abs() > 1e-12 ? (0.5 * (a - c) / denom).clamp(-0.5, 0.5) : 0.0;
      return PeakEstimate((best + delta) * bin, _amplitudeDb(math.exp(b - 0.25 * (a - c) * delta)), best);
    }
    final half = windowKind.lobeHalfWidth;
    final start = math.max(1, math.max(lo - 1, best - half));
    final end = math.min(last - 1, math.min(hi + 1, best + half));
    var total = 0.0, moment = 0.0;
    for (var k = start; k <= end; k++) {
      total += power[k];
      moment += k * power[k];
    }
    return PeakEstimate(
      moment / total * bin,
      10 * math.log(math.max(total, 1e-30)) / math.ln10 + calibrationOffsetDb,
      best,
    );
  }
}

/// Các bin (tăng dần) phủ một dải tần và tỷ lệ phủ của từng bin.
class _BandPlan {
  const _BandPlan(this.bins, this.overlaps);
  final Int32List bins;
  final Float64List overlaps;
}
