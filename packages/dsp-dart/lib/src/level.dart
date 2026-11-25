import 'dart:math' as math;
import 'dart:typed_data';

import 'weighting.dart';

/// Hằng thời gian chuẩn IEC 61672-1 (giây).
const double tauFast = 0.125;
const double tauSlow = 1.0;
const double tauImpulseRise = 0.035;
const double tauImpulseDecay = 1.5;
const double statIntervalS = 0.01;

const double _floorMs = 1e-20;
const double _histMinDb = -50;
const double _histStepDb = 0.1;
const int _histBins = 3000;

enum TimeWeighting {
  fast('F'),
  slow('S'),
  impulse('I');

  const TimeWeighting(this.label);
  final String label;
}

/// Tiêu chuẩn liều tiếp xúc tiếng ồn.
class DoseCriterion {
  const DoseCriterion(this.name, this.criterionDb, this.exchangeRateDb, this.thresholdDb);

  final String name;
  final double criterionDb;
  final double exchangeRateDb;
  final double thresholdDb;

  double allowedSeconds(double levelDb) => 8 * 3600 / math.pow(2, (levelDb - criterionDb) / exchangeRateDb);

  double twaDb(double dosePercent) {
    if (dosePercent <= 0) return double.negativeInfinity;
    return criterionDb + exchangeRateDb * math.log(dosePercent / 100) / math.ln2;
  }
}

const niosh = DoseCriterion('NIOSH', 85, 3, 80);
const osha = DoseCriterion('OSHA', 90, 5, 80);

const List<double> percentileLevels = [1, 5, 10, 50, 90, 95, 99];

double _toDb(double ms, double offset) => 10 * math.log(math.max(ms, _floorMs)) / math.ln10 + offset;

class _Detector {
  _Detector(Weighting weighting, double sampleRate) : filter = WeightingFilter(weighting, sampleRate);

  final WeightingFilter filter;
  double fast = 0, slow = 0, impulse = 0, sumSq = 0, peakAbs = 0;
  final Float64List maxMs = Float64List(3);
  final Float64List minMs = Float64List.fromList([double.infinity, double.infinity, double.infinity]);

  void resetStats() {
    sumSq = 0;
    peakAbs = 0;
    maxMs.fillRange(0, 3, 0);
    minMs.fillRange(0, 3, double.infinity);
  }
}

/// Ảnh chụp mức âm; chỉ số trọng số tần số theo thứ tự A, C, Z
/// và trọng số thời gian theo thứ tự F, S, I.
class LevelSnapshot {
  LevelSnapshot({
    required this.instant,
    required this.leq,
    required this.max,
    required this.min,
    required this.peak,
    required this.percentiles,
    required this.selA,
    required this.doseNioshPercent,
    required this.doseOshaPercent,
    required this.twaNiosh,
    required this.twaOsha,
    required this.elapsedSeconds,
  });

  final List<List<double>> instant;
  final List<double> leq;
  final List<List<double>> max;
  final List<List<double>> min;
  final List<double> peak;
  final List<double> percentiles;
  final double selA;
  final double doseNioshPercent;
  final double doseOshaPercent;
  final double twaNiosh;
  final double twaOsha;
  final double elapsedSeconds;

  double level(Weighting w, TimeWeighting t) => instant[w.index][t.index];

  /// Cùng bố cục 46 số với `LevelSnapshot::to_flat` của Rust.
  List<double> toFlat() => [
    for (final row in instant) ...row,
    ...leq,
    for (final row in max) ...row,
    for (final row in min) ...row,
    ...peak,
    ...percentiles,
    selA,
    doseNioshPercent,
    doseOshaPercent,
    twaNiosh,
    twaOsha,
    elapsedSeconds,
  ];
}

/// Máy đo mức âm theo luồng - bản port của `SoundLevelMeter` (Rust).
class SoundLevelMeter {
  SoundLevelMeter(this.sampleRate, this.calibrationOffsetDb)
    : _detectors = [for (final w in Weighting.values) _Detector(w, sampleRate)],
      _alphaFast = _alpha(tauFast, sampleRate),
      _alphaSlow = _alpha(tauSlow, sampleRate),
      _alphaRise = _alpha(tauImpulseRise, sampleRate),
      _alphaDecay = _alpha(tauImpulseDecay, sampleRate),
      _statPeriod = math.max(1, (statIntervalS * sampleRate).round()),
      _scratch = Float64List(math.max(1, (statIntervalS * sampleRate).round()));

  final double sampleRate;
  double calibrationOffsetDb;
  final List<_Detector> _detectors;
  final double _alphaFast, _alphaSlow, _alphaRise, _alphaDecay;
  final int _statPeriod;

  /// Mẫu đã lọc của một đoạn (≤ một chu kỳ thống kê) - dùng lại, không cấp phát theo khối.
  final Float64List _scratch;
  int _samples = 0;
  int _statCounter = 0;
  final Uint32List _histogram = Uint32List(_histBins);
  int _histogramCount = 0;
  double _doseNiosh = 0;
  double _doseOsha = 0;

  static double _alpha(double tau, double fs) => 1 - math.exp(-1 / (tau * fs));

  double get elapsedSeconds => _samples / sampleRate;

  /// Số mẫu đã đo trong phiên.
  int get sampleCount => _samples;

  /// Tổng bình phương tín hiệu đã lọc trọng số [w] từ đầu phiên (để tính Leq
  /// cho từng khoảng con: lấy hiệu hai lần đọc chia số mẫu).
  double weightedSumSquares(Weighting w) => _detectors[w.index].sumSq;

  void resetSession() {
    for (final d in _detectors) {
      d.resetStats();
    }
    _samples = 0;
    _statCounter = 0;
    _histogram.fillRange(0, _histBins, 0);
    _histogramCount = 0;
    _doseNiosh = 0;
    _doseOsha = 0;
  }

  /// Xử lý theo đoạn, mỗi đoạn kết thúc đúng mốc thống kê (10 ms) để [_updateStats] thấy cùng trạng thái như khi xử
  /// lý từng mẫu. Trong đoạn: từng bộ lọc chạy hết đoạn với biến cục bộ. Kết quả trùng bit bản từng mẫu (QA-11 bước 4,
  /// test/qa11_block_rfft_test.dart) - bản Rust tham chiếu không đổi.
  void process(Float32List block) {
    final n = block.length;
    var i = 0;
    while (i < n) {
      final end = math.min(n, i + _statPeriod - _statCounter);
      final len = end - i;
      for (final d in _detectors) {
        d.filter.processBlock(block, i, end, _scratch);
        _runDetector(d, len);
      }
      _samples += len;
      _statCounter += len;
      if (_statCounter >= _statPeriod) {
        _statCounter = 0;
        _updateStats();
      }
      i = end;
    }
  }

  void _runDetector(_Detector d, int n) {
    final buf = _scratch;
    final aFast = _alphaFast, aSlow = _alphaSlow, aRise = _alphaRise, aDecay = _alphaDecay;
    var fast = d.fast, slow = d.slow, impulse = d.impulse, sumSq = d.sumSq, peakAbs = d.peakAbs;
    for (var j = 0; j < n; j++) {
      final y = buf[j];
      final sq = y * y;
      fast += aFast * (sq - fast);
      slow += aSlow * (sq - slow);
      impulse += (sq > impulse ? aRise : aDecay) * (sq - impulse);
      sumSq += sq;
      final abs = y.abs();
      if (abs > peakAbs) peakAbs = abs;
    }
    d
      ..fast = fast
      ..slow = slow
      ..impulse = impulse
      ..sumSq = sumSq
      ..peakAbs = peakAbs;
  }

  void _updateStats() {
    final settled = _samples >= 0.5 * sampleRate;
    for (final d in _detectors) {
      final values = [d.fast, d.slow, d.impulse];
      for (var i = 0; i < 3; i++) {
        if (values[i] > d.maxMs[i]) d.maxMs[i] = values[i];
        if (settled && values[i] < d.minMs[i]) d.minMs[i] = values[i];
      }
    }
    final laf = _toDb(_detectors[0].fast, calibrationOffsetDb);
    final bin = ((laf - _histMinDb) / _histStepDb).floor().clamp(0, _histBins - 1);
    _histogram[bin]++;
    _histogramCount++;
    final las = _toDb(_detectors[0].slow, calibrationOffsetDb);
    final dt = _statPeriod / sampleRate;
    if (las >= niosh.thresholdDb) _doseNiosh += 100 * dt / niosh.allowedSeconds(las);
    if (las >= osha.thresholdDb) _doseOsha += 100 * dt / osha.allowedSeconds(las);
  }

  double percentile(double exceededPercent) {
    if (_histogramCount == 0) return double.nan;
    final target = math.max(1, (_histogramCount * exceededPercent / 100).ceil());
    var cumulative = 0;
    for (var i = _histBins - 1; i >= 0; i--) {
      cumulative += _histogram[i];
      if (cumulative >= target) return _histMinDb + (i + 0.5) * _histStepDb;
    }
    return _histMinDb;
  }

  /// Mọi mức của [percentileLevels] trong MỘT lượt quét histogram (cùng kết quả gọi [percentile] từng mức - các mức
  /// tăng dần nên ngưỡng đếm cũng tăng dần). Trước: 7 lượt × 3000 ô mỗi ảnh chụp, 20 ảnh/giây (QA-11 bước 4).
  List<double> _allPercentiles() {
    const levels = percentileLevels;
    if (_histogramCount == 0) return List<double>.filled(levels.length, double.nan);
    final out = List<double>.filled(levels.length, _histMinDb);
    var j = 0;
    var target = math.max(1, (_histogramCount * levels[0] / 100).ceil());
    var cumulative = 0;
    for (var i = _histBins - 1; i >= 0 && j < levels.length; i--) {
      cumulative += _histogram[i];
      while (j < levels.length && cumulative >= target) {
        out[j++] = _histMinDb + (i + 0.5) * _histStepDb;
        if (j < levels.length) target = math.max(1, (_histogramCount * levels[j] / 100).ceil());
      }
    }
    return out;
  }

  /// Mức tức thời một trọng số - bằng `snapshot().level(w, t)` nhưng không dựng cả ảnh chụp.
  double instantDb(Weighting w, TimeWeighting t) {
    final d = _detectors[w.index];
    final ms = switch (t) {
      TimeWeighting.fast => d.fast,
      TimeWeighting.slow => d.slow,
      TimeWeighting.impulse => d.impulse,
    };
    return _toDb(ms, calibrationOffsetDb);
  }

  LevelSnapshot snapshot() {
    final off = calibrationOffsetDb;
    final elapsed = elapsedSeconds;
    final leq = [for (final d in _detectors) _samples > 0 ? _toDb(d.sumSq / _samples, off) : double.nan];
    return LevelSnapshot(
      instant: [
        for (final d in _detectors) [_toDb(d.fast, off), _toDb(d.slow, off), _toDb(d.impulse, off)],
      ],
      leq: leq,
      max: [
        for (final d in _detectors) [for (var t = 0; t < 3; t++) d.maxMs[t] > 0 ? _toDb(d.maxMs[t], off) : double.nan],
      ],
      min: [
        for (final d in _detectors)
          [for (var t = 0; t < 3; t++) d.minMs[t].isFinite ? _toDb(d.minMs[t], off) : double.nan],
      ],
      peak: [for (final d in _detectors) d.peakAbs > 0 ? _toDb(d.peakAbs * d.peakAbs, off) : double.nan],
      percentiles: _allPercentiles(),
      selA: _samples > 0 ? leq[0] + 10 * math.log(elapsed) / math.ln10 : double.nan,
      doseNioshPercent: _doseNiosh,
      doseOshaPercent: _doseOsha,
      twaNiosh: niosh.twaDb(_doseNiosh),
      twaOsha: osha.twaDb(_doseOsha),
      elapsedSeconds: elapsed,
    );
  }
}
