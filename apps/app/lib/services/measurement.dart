import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/models.dart';
import 'audio_input.dart';
import 'settings.dart';

enum MeterState { idle, starting, running, paused, error }

/// Bộ điều phối đo: nhận mẫu từ micro, đẩy vào lõi DSP, và ở nhịp hiển thị
/// (~20 khung/giây) cập nhật ảnh chụp mức, phổ, phổ đồ, cao độ cho giao diện.
class MeasurementController extends ChangeNotifier {
  MeasurementController(this.settings, {AudioInput? input}) : _input = input ?? AudioInput() {
    _engine = _newEngine();
    settings.addListener(_onSettings);
  }

  final Settings settings;
  final AudioInput _input;
  late Engine _engine;
  StreamSubscription<Float32List>? _subscription;
  Ticker? _ticker;
  Duration _lastFrame = Duration.zero;

  MeterState state = MeterState.idle;
  String? error;
  DateTime? startedAt;
  LevelSnapshot? snapshot;
  PeakEstimate? peak;
  PitchEstimate? pitch;
  Float64List spectrumDb = Float64List(0);
  Float64List peakHoldDb = Float64List(0);
  List<double> thirdOctave = const [];
  List<double> fullOctave = const [];

  /// Mức tức thời (trọng số đang chọn) mỗi 100 ms trong 2 phút gần nhất.
  final List<double> levelHistory = [];
  static const int historyLength = 1200;

  /// Phổ đồ: mỗi hàng 256 ô tần số log (20 Hz - Nyquist), tối đa 240 hàng.
  final List<Float32List> spectrogram = [];
  static const int spectrogramColumns = 256;
  static const int spectrogramRows = 240;

  /// LAeq từng giây của phiên (để lưu), và tích lũy công suất 1/3 octave.
  final List<double> _laeqPerSecond = [];
  double _secondStartSum = 0;
  int _secondStartCount = 0;
  final List<double> _thirdOctavePowerSum = [];
  int _thirdOctaveFrames = 0;
  int _samplesSinceHistory = 0;

  Engine get engine => _engine;
  double get sampleRate => _engine.sampleRate;
  bool get isRunning => state == MeterState.running;

  Engine _newEngine() => Engine(
        sampleRate: _input.sampleRate.toDouble(),
        fftSize: settings.fftSize,
        window: settings.window,
        calibrationOffsetDb: settings.calibrationOffsetDb,
      );

  void _onSettings() {
    _engine.calibrationOffsetDb = settings.calibrationOffsetDb;
    if (_engine.spectrum.size != settings.fftSize || _engine.spectrum.windowKind != settings.window) {
      _engine.configureSpectrum(settings.fftSize, settings.window);
      peakHoldDb = Float64List(0);
    }
  }

  Future<void> start() async {
    if (state == MeterState.running || state == MeterState.starting) return;
    state = MeterState.starting;
    error = null;
    notifyListeners();
    try {
      if (state != MeterState.paused) _resetSessionData();
      _subscription = _input.samples.listen(_onSamples, onError: _onError);
      await _input.start();
      startedAt ??= DateTime.now();
      state = MeterState.running;
      _ticker ??= Ticker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();
      if (settings.keepScreenOn) unawaited(WakelockPlus.enable().catchError((_) {}));
    } catch (e) {
      _onError(e);
    }
    notifyListeners();
  }

  void _onError(Object e) {
    error = e is AudioInputException ? e.message : 'Không mở được micro: $e';
    state = MeterState.error;
    unawaited(_stopInput());
    notifyListeners();
  }

  Future<void> _stopInput() async {
    await _subscription?.cancel();
    _subscription = null;
    await _input.stop();
    _ticker?.stop();
    unawaited(WakelockPlus.disable().catchError((_) {}));
  }

  Future<void> pause() async {
    if (state != MeterState.running) return;
    await _stopInput();
    state = MeterState.paused;
    notifyListeners();
  }

  /// Xóa phiên đang đo (Leq, Max/Min, liều, lịch sử) nhưng vẫn đo tiếp.
  void resetSession() {
    _resetSessionData();
    notifyListeners();
  }

  void _resetSessionData() {
    _engine.resetSession();
    startedAt = state == MeterState.running ? DateTime.now() : null;
    levelHistory.clear();
    spectrogram.clear();
    _laeqPerSecond.clear();
    _secondStartSum = 0;
    _secondStartCount = 0;
    _thirdOctavePowerSum.clear();
    _thirdOctaveFrames = 0;
    peakHoldDb = Float64List(0);
    snapshot = null;
  }

  void _onSamples(Float32List block) {
    _engine.push(block);
    // LAeq từng giây cho chuỗi thời gian của phiên: lấy hiệu năng lượng A tích
    // lũy giữa hai mốc (đúng nghĩa Leq), không lấy mẫu mức F tức thời.
    final fs = _engine.sampleRate.round();
    final meter = _engine.meter;
    final count = meter.sampleCount;
    if (count - _secondStartCount >= fs) {
      final sum = meter.weightedSumSquares(Weighting.a);
      final ms = (sum - _secondStartSum) / (count - _secondStartCount);
      _laeqPerSecond.add(10 * math.log(math.max(ms, 1e-20)) / math.ln10 + _engine.calibrationOffsetDb);
      _secondStartSum = sum;
      _secondStartCount = count;
    }
    _samplesSinceHistory += block.length;
    if (_samplesSinceHistory >= fs ~/ 10) {
      _samplesSinceHistory = 0;
      final s = _engine.meter.snapshot();
      levelHistory.add(s.level(settings.weighting, settings.timeWeighting));
      if (levelHistory.length > historyLength) levelHistory.removeAt(0);
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastFrame < const Duration(milliseconds: 50)) return;
    _lastFrame = elapsed;
    if (_engine.totalSamples < _engine.spectrum.size) return;
    _engine.analyzeSpectrum();
    final spectrum = _engine.spectrum;
    if (spectrumDb.length != spectrum.bins) {
      spectrumDb = Float64List(spectrum.bins);
      peakHoldDb = Float64List(spectrum.bins);
    }
    spectrum.spectrumDb(settings.weighting, spectrumDb);
    spectrum.spectrumDb(settings.weighting, peakHoldDb, fromPeakHold: true);
    peak = spectrum.dominantPeak(20, math.min(20000, sampleRate / 2 - spectrum.binHz * 8));
    pitch = _engine.detectPitch();
    thirdOctave = _engine.bandLevels(3, settings.weighting);
    fullOctave = _engine.bandLevels(1, settings.weighting);
    _accumulateThirdOctave();
    _appendSpectrogramRow();
    snapshot = _engine.meter.snapshot();
    notifyListeners();
  }

  void _accumulateThirdOctave() {
    final z = _engine.bandLevels(3, Weighting.z);
    if (_thirdOctavePowerSum.length != z.length) {
      _thirdOctavePowerSum
        ..clear()
        ..addAll(List.filled(z.length, 0));
      _thirdOctaveFrames = 0;
    }
    for (var i = 0; i < z.length; i++) {
      _thirdOctavePowerSum[i] += math.pow(10, z[i] / 10).toDouble();
    }
    _thirdOctaveFrames++;
  }

  void _appendSpectrogramRow() {
    final row = Float32List(spectrogramColumns);
    final binHz = _engine.spectrum.binHz;
    final nyquist = sampleRate / 2;
    final lo = math.log(20), hi = math.log(nyquist);
    for (var c = 0; c < spectrogramColumns; c++) {
      final f0 = math.exp(lo + (hi - lo) * c / spectrogramColumns);
      final f1 = math.exp(lo + (hi - lo) * (c + 1) / spectrogramColumns);
      final k0 = (f0 / binHz).floor().clamp(0, spectrumDb.length - 1);
      final k1 = math.max(k0, (f1 / binHz).floor().clamp(0, spectrumDb.length - 1));
      var best = double.negativeInfinity;
      for (var k = k0; k <= k1; k++) {
        if (spectrumDb[k] > best) best = spectrumDb[k];
      }
      row[c] = best;
    }
    spectrogram.add(row);
    if (spectrogram.length > spectrogramRows) spectrogram.removeAt(0);
  }

  /// Chỉ cho test: đẩy mẫu như từ micro rồi chạy một nhịp hiển thị.
  @visibleForTesting
  void debugProcess(Float32List block) {
    _onSamples(block);
    startedAt ??= DateTime.now();
    _lastFrame = Duration.zero;
    _onTick(const Duration(days: 1));
  }

  void clearPeakHold() {
    _engine.spectrum.peakHold.fillRange(0, _engine.spectrum.peakHold.length, 0);
    notifyListeners();
  }

  /// Chốt phiên hiện tại thành bản ghi để lưu (không dừng đo).
  MeasurementSession? buildSession({required String label, required String deviceModel}) {
    final s = _engine.meter.snapshot();
    if (s.elapsedSeconds < 1 || startedAt == null) return null;
    double? f(double v) => v.isFinite ? double.parse(v.toStringAsFixed(2)) : null;
    var series = List<double>.from(_laeqPerSecond);
    if (series.length > MeasurementSession.maxSeriesPoints) {
      // Gộp năng lượng từng nhóm để giữ đúng Leq của nhóm.
      final group = (series.length / MeasurementSession.maxSeriesPoints).ceil();
      series = [
        for (var i = 0; i < series.length; i += group)
          () {
            final part = series.sublist(i, math.min(i + group, series.length));
            final mean = part.map((v) => math.pow(10, v / 10)).reduce((a, b) => a + b) / part.length;
            return 10 * math.log(mean) / math.ln10;
          }(),
      ];
    }
    final bands = _engine.bands(3);
    return MeasurementSession(
      id: const Uuid().v7(),
      startedAt: startedAt!,
      durationSeconds: s.elapsedSeconds,
      label: label,
      note: '',
      summary: {
        'laeq': f(s.leq[0]),
        'lceq': f(s.leq[1]),
        'lzeq': f(s.leq[2]),
        'lafmax': f(s.max[0][0]),
        'lafmin': f(s.min[0][0]),
        'lasmax': f(s.max[0][1]),
        'lcpeak': f(s.peak[1]),
        'l10': f(s.percentiles[2]),
        'l50': f(s.percentiles[3]),
        'l90': f(s.percentiles[4]),
        'dose_niosh': f(s.doseNioshPercent),
        'dose_osha': f(s.doseOshaPercent),
        'twa_niosh': f(s.twaNiosh),
        'sel_a': f(s.selA),
      },
      seriesLaeq: [for (final v in series) double.parse(v.toStringAsFixed(1))],
      thirdOctaveLzeq: {
        if (_thirdOctaveFrames > 0)
          for (var i = 0; i < bands.length && i < _thirdOctavePowerSum.length; i++)
            bands[i].nominalHz.toString():
                double.parse((10 * math.log(_thirdOctavePowerSum[i] / _thirdOctaveFrames) / math.ln10).toStringAsFixed(1)),
      },
      calibrationOffsetDb: settings.calibrationOffsetDb,
      deviceModel: deviceModel,
      platform: AudioInput.platformName,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  void dispose() {
    settings.removeListener(_onSettings);
    _ticker?.dispose();
    unawaited(_stopInput().then((_) => _input.dispose()));
    super.dispose();
  }
}
