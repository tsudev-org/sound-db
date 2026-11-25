import 'dart:math' as math;
import 'dart:typed_data';

import 'fft.dart';

class PitchEstimate {
  const PitchEstimate(this.frequencyHz, this.clarity);
  final double frequencyHz;
  final double clarity;
}

const List<String> noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

class NoteInfo {
  const NoteInfo(this.midi, this.cents, this.octave, this.pitchClass);
  final int midi;
  final double cents;
  final int octave;
  final int pitchClass;

  String get name => '${noteNames[pitchClass]}$octave';
}

NoteInfo? noteInfo(double frequencyHz, double a4Hz) {
  if (frequencyHz.isNaN || a4Hz.isNaN || frequencyHz <= 0 || a4Hz <= 0) return null;
  final exact = 69 + 12 * math.log(frequencyHz / a4Hz) / math.ln2;
  final midi = exact.round();
  // `%` của Dart luôn không âm nên (midi - midi % 12) ~/ 12 là phép chia Euclid.
  return NoteInfo(midi, (exact - midi) * 100, (midi - midi % 12) ~/ 12 - 1, midi % 12);
}

/// Dò cao độ McLeod (NSDF) - bản port của `PitchDetector` (Rust).
class PitchDetector {
  PitchDetector(this.size, this.sampleRate)
    : _padded = _nextPow2(2 * size),
      _nsdf = Float64List(size),
      _squares = Float64List(size) {
    _fft = RealFft(_padded);
    _signal = Float64List(_padded);
    _re = Float64List(_padded ~/ 2 + 1);
    _im = Float64List(_padded ~/ 2 + 1);
  }

  static int _nextPow2(int v) {
    var p = 1;
    while (p < v) {
      p <<= 1;
    }
    return p;
  }

  final int size;
  final double sampleRate;
  final int _padded;
  // FFT thực thuận + ngược (QA-11 bước 4): tự tương quan qua phổ công suất, nửa chi phí FFT phức cùng cỡ.
  late final RealFft _fft;
  late final Float64List _signal, _re, _im;
  final Float64List _nsdf, _squares;
  double minHz = 30;
  double maxHz = 5000;
  double threshold = 0.9;

  PitchEstimate? detect(Float32List frame) {
    assert(frame.length == size);
    final n = size;
    var mean = 0.0;
    for (var i = 0; i < n; i++) {
      mean += frame[i];
    }
    mean /= n;
    _signal.fillRange(n, _padded, 0);
    var energy = 0.0;
    final squares = _squares;
    for (var i = 0; i < n; i++) {
      final v = frame[i] - mean;
      _signal[i] = v;
      squares[i] = v * v;
      energy += squares[i];
    }
    if (energy < 1e-12) return null;
    _fft.forward(_signal, _re, _im);
    for (var i = 0; i < _re.length; i++) {
      _re[i] = _re[i] * _re[i] + _im[i] * _im[i];
      _im[i] = 0;
    }
    _fft.inverse(_re, _im, _signal);
    final scale = 1 / _padded;
    var m = 2 * energy;
    for (var tau = 0; tau < n; tau++) {
      if (tau > 0) m -= squares[n - tau] + squares[tau - 1];
      _nsdf[tau] = m > 1e-12 ? 2 * _signal[tau] * scale / m : 0;
    }
    final minTau = math.max(2, (sampleRate / maxHz).floor());
    final maxTau = math.min(n - 2, (sampleRate / minHz).ceil());
    if (minTau >= maxTau) return null;
    final keyMaxima = <int>[];
    var tau = 1;
    while (tau < maxTau && _nsdf[tau] > 0) {
      tau++;
    }
    while (tau < maxTau) {
      if (_nsdf[tau] > 0) {
        var best = tau;
        while (tau < maxTau && _nsdf[tau] > 0) {
          if (_nsdf[tau] > _nsdf[best]) best = tau;
          tau++;
        }
        if (best >= minTau) keyMaxima.add(best);
      }
      tau++;
    }
    var highest = 0.0;
    for (final t in keyMaxima) {
      highest = math.max(highest, _nsdf[t]);
    }
    if (highest <= 0) return null;
    final chosen = keyMaxima.where((t) => _nsdf[t] >= threshold * highest).firstOrNull;
    if (chosen == null) return null;
    final a = _nsdf[chosen - 1], b = _nsdf[chosen], c = _nsdf[chosen + 1];
    final denom = a - 2 * b + c;
    final delta = denom.abs() > 1e-12 ? (0.5 * (a - c) / denom).clamp(-0.5, 0.5) : 0.0;
    return PitchEstimate(sampleRate / (chosen + delta), math.min(1, b - 0.25 * (a - c) * delta));
  }
}
