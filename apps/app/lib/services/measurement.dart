import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/models.dart';
import 'audio_input.dart';
import 'settings.dart';
import '../l10n/l10n.dart';

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

  /// Nhịp hiển thị 20 lần/giây. KHÔNG dùng Ticker: nó xin khung ở mọi vsync (90 Hz) dù dữ liệu chỉ đổi mỗi 50 ms, mỗi
  /// khung raster lại toàn màn và DSP chạy trong khung ⇒ giật 27-56% trên máy thật (QA-04, 23/11/2026).
  Timer? _ticker;
  static const _tickInterval = Duration(milliseconds: 50);

  MeterState state = MeterState.idle;
  String? error;

  /// Mã lỗi máy đọc được (vd. [AudioInputException.permissionDenied]) để giao diện chọn hành động kèm theo.
  String? errorCode;
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

  /// Tăng mỗi khi [snapshot] được làm mới (10 lần/giây, mỗi 2 nhịp) hoặc phiên bị xoá. Trang Đo mức và đồ thị chỉ
  /// dựng/vẽ lại theo số này: trọng số F = 125 ms nên 10 khung/giây đủ cho mắt, và gom đồ thị (10 điểm/giây) vào
  /// cùng khung với số đo thay vì hai khung lệch nhịp (QA-11 bước 3 vòng 2).
  int displayVersion = 0;

  /// Tăng mỗi khi [levelHistory] đổi - đồ thị chỉ vẽ lại khi số này đổi (10 lần/giây, không phải 20).
  int historyVersion = 0;
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

  /// Số màn đang HIỂN THỊ cần cao độ. Dò cao độ (FFT 8192 thuận + ngược) chiếm ~1/2 DSP còn lại sau khi lập bảng dải
  /// octave, nhưng chỉ Bộ chỉnh âm dùng; các trang nằm trong IndexedStack nên "đang gắn" không có nghĩa "đang xem"
  /// (QA-11, 24/11/2026).
  int _pitchDemand = 0;

  /// Màn cần cao độ gọi `true` khi bắt đầu hiển thị, `false` khi ẩn (gọi theo cặp).
  void demandPitch(bool wanted) {
    _pitchDemand = math.max(0, _pitchDemand + (wanted ? 1 : -1));
    if (_pitchDemand == 0) pitch = null;
  }

  @visibleForTesting
  bool get pitchDemanded => _pitchDemand > 0;

  /// Số màn đang HIỂN THỊ cần phổ (Phân tích: phổ FFT, phổ đồ, dải octave). FFT phổ chiếm 18 % CPU Dart ở tab Đo mức
  /// dù tab đó không hiện phổ (hồ sơ máy thật QA-11 bước 3, 25/11/2026). Không ai xem ⇒ chỉ phân tích mỗi
  /// [_accumulateEvery] nhịp để tích luỹ 1/3 octave cho phiên lưu.
  int _spectrumDemand = 0;

  /// Tích luỹ 1/3 octave của phiên mỗi 4 nhịp (200 ms) dù có ai xem phổ hay không - trọng số theo thời gian giữ đều.
  /// Khung FFT 8192 mẫu @ 48 kHz = 171 ms, phổ đã làm trơn hàm mũ ⇒ 5 khung/giây đủ cho mức trung bình dải.
  static const int _accumulateEvery = 4;
  int _tickIndex = 0;
  int _spectrumAnalyses = 0;

  /// Màn cần phổ gọi `true` khi bắt đầu hiển thị, `false` khi ẩn (gọi theo cặp). Bắt đầu xem lại ⇒ xoá phổ đồ cũ
  /// (khoảng thời gian không xem không có hàng - giữ hàng cũ sẽ ghép hai thời điểm xa nhau như liền nhau).
  void demandSpectrum(bool wanted) {
    final before = _spectrumDemand;
    _spectrumDemand = math.max(0, _spectrumDemand + (wanted ? 1 : -1));
    if (before == 0 && _spectrumDemand > 0) {
      spectrogram.clear();
      // Trang vừa hiện: công bố ngay phổ đã phân tích gần nhất (≤ 200 ms), không chờ nhịp kế. KHÔNG báo listener - hàm
      // này được gọi trong lúc dựng cây; các phần nghe đã lỡ thông báo khi ẩn sẽ tự dựng lại lúc hiện.
      if (_spectrumAnalyses > 0) _publishSpectrum();
    }
  }

  @visibleForTesting
  bool get spectrumDemanded => _spectrumDemand > 0;

  /// Số lần đã phân tích phổ (test kiểm nhịp phân tích).
  @visibleForTesting
  int get spectrumAnalyses => _spectrumAnalyses;

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
    // Phải đọc TRƯỚC khi gán starting: kiểm sau đó thì luôn "không tạm dừng" và nút Tiếp tục xoá sạch phiên (QA-03).
    final resuming = state == MeterState.paused;
    state = MeterState.starting;
    error = null;
    errorCode = null;
    notifyListeners();
    try {
      if (!resuming) _resetSessionData();
      _subscription = _input.samples.listen(_onSamples, onError: _onError);
      await _input.start();
      startedAt ??= DateTime.now();
      state = MeterState.running;
      _ticker ??= Timer.periodic(_tickInterval, (_) => _onTick());
      if (settings.keepScreenOn) unawaited(WakelockPlus.enable().catchError((_) {}));
    } catch (e) {
      _onError(e);
    }
    notifyListeners();
  }

  void _onError(Object e) {
    error = e is AudioInputException ? e.message : l10nNow.errMicOpen('$e');
    errorCode = e is AudioInputException ? e.code : null;
    state = MeterState.error;
    unawaited(_stopInput());
    notifyListeners();
  }

  Future<void> _stopInput() async {
    await _subscription?.cancel();
    _subscription = null;
    await _input.stop();
    _ticker?.cancel();
    _ticker = null;
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
    historyVersion++;
    displayVersion++;
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
      // Chỉ cần một mức - không dựng cả ảnh chụp (phân vị quét histogram) 10 lần/giây (QA-11 bước 4).
      levelHistory.add(_engine.meter.instantDb(settings.weighting, settings.timeWeighting));
      if (levelHistory.length > historyLength) levelHistory.removeAt(0);
      historyVersion++;
    }
  }

  void _onTick() {
    if (_engine.totalSamples < _engine.spectrum.size) return;
    final tick = _tickIndex++;
    final accumulate = tick % _accumulateEvery == 0;
    final show = _spectrumDemand > 0;
    if (show || accumulate) {
      _engine.analyzeSpectrum();
      _spectrumAnalyses++;
    }
    if (accumulate) _accumulateThirdOctave();
    if (show) _publishSpectrum();
    pitch = _pitchDemand > 0 ? _engine.detectPitch() : null;
    if (tick.isEven) {
      snapshot = _engine.meter.snapshot();
      displayVersion++;
    }
    notifyListeners();
  }

  /// Phần chỉ trang Phân tích hiển thị: phổ dB, giữ đỉnh, đỉnh mạnh nhất, dải octave, một hàng phổ đồ.
  void _publishSpectrum() {
    final spectrum = _engine.spectrum;
    if (spectrumDb.length != spectrum.bins) {
      spectrumDb = Float64List(spectrum.bins);
      peakHoldDb = Float64List(spectrum.bins);
    }
    spectrum.spectrumDb(settings.weighting, spectrumDb);
    spectrum.spectrumDb(settings.weighting, peakHoldDb, fromPeakHold: true);
    peak = spectrum.dominantPeak(20, math.min(20000, sampleRate / 2 - spectrum.binHz * 8));
    thirdOctave = _engine.bandLevels(3, settings.weighting);
    fullOctave = _engine.bandLevels(1, settings.weighting);
    _appendSpectrogramRow();
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
    _onTick();
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
            bands[i].nominalHz.toString(): double.parse(
              (10 * math.log(_thirdOctavePowerSum[i] / _thirdOctaveFrames) / math.ln10).toStringAsFixed(1),
            ),
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
    _ticker?.cancel();
    unawaited(_stopInput().then((_) => _input.dispose()));
    super.dispose();
  }
}
