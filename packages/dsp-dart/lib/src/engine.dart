import 'dart:typed_data';

import 'level.dart';
import 'octave.dart';
import 'pitch.dart';
import 'spectrum.dart';
import 'weighting.dart';

/// Gom các bộ phân tích quanh một vòng đệm mẫu (giống `Engine` của Rust).
class Engine {
  Engine({
    required this.sampleRate,
    int fftSize = 8192,
    WindowKind window = WindowKind.hann,
    double calibrationOffsetDb = 0,
  })  : meter = SoundLevelMeter(sampleRate, calibrationOffsetDb),
        _spectrum = SpectrumAnalyzer(fftSize, sampleRate, window, calibrationOffsetDb),
        _pitch = PitchDetector(pitchFrame, sampleRate),
        thirdOctaveBands = octaveBands(3, 10, sampleRate / 2 / 1.13),
        fullOctaveBands = octaveBands(1, 15, sampleRate / 2 / 1.42);

  static const int ringSize = 65536;
  static const int pitchFrame = 4096;

  final double sampleRate;
  final SoundLevelMeter meter;
  SpectrumAnalyzer _spectrum;
  final PitchDetector _pitch;
  final List<Band> thirdOctaveBands;
  final List<Band> fullOctaveBands;
  final Float32List _ring = Float32List(ringSize);
  int _ringPos = 0;
  int _totalSamples = 0;

  SpectrumAnalyzer get spectrum => _spectrum;
  int get totalSamples => _totalSamples;

  set calibrationOffsetDb(double value) {
    meter.calibrationOffsetDb = value;
    _spectrum.calibrationOffsetDb = value;
  }

  double get calibrationOffsetDb => meter.calibrationOffsetDb;

  void configureSpectrum(int fftSize, WindowKind window, {Averaging? averaging, double? expAlpha}) {
    final previous = _spectrum;
    _spectrum = SpectrumAnalyzer(fftSize, sampleRate, window, meter.calibrationOffsetDb)
      ..averaging = averaging ?? previous.averaging
      ..expAlpha = expAlpha ?? previous.expAlpha;
  }

  void push(Float32List samples) {
    meter.process(samples);
    for (var i = 0; i < samples.length; i++) {
      _ring[_ringPos] = samples[i];
      _ringPos = (_ringPos + 1) & (ringSize - 1);
    }
    _totalSamples += samples.length;
  }

  Float32List latest(int size) {
    final out = Float32List(size);
    var start = (_ringPos - size) & (ringSize - 1);
    for (var i = 0; i < size; i++) {
      out[i] = _ring[start];
      start = (start + 1) & (ringSize - 1);
    }
    return out;
  }

  void analyzeSpectrum() => _spectrum.analyze(latest(_spectrum.size));

  PitchEstimate? detectPitch() => _pitch.detect(latest(pitchFrame));

  List<Band> bands(int fraction) => fraction == 1 ? fullOctaveBands : thirdOctaveBands;

  List<double> bandLevels(int fraction, Weighting weighting) =>
      [for (final b in bands(fraction)) _spectrum.bandLevelDb(b.lowerHz, b.upperHz, weighting)];

  void resetSession() {
    meter.resetSession();
    _spectrum.reset();
  }
}
