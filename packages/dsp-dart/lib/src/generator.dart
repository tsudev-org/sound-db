import 'dart:math' as math;
import 'dart:typed_data';

enum Waveform {
  sine('Sin'),
  square('Vuông'),
  sawtooth('Răng cưa'),
  triangle('Tam giác'),
  whiteNoise('Ồn trắng'),
  pinkNoise('Ồn hồng'),
  logSweep('Quét tần số');

  const Waveform(this.label);
  final String label;
}

/// Bộ phát tín hiệu thử - bản port của `SignalGenerator` (Rust).
class SignalGenerator {
  SignalGenerator(this.sampleRate);

  final double sampleRate;
  Waveform waveform = Waveform.sine;
  double frequencyHz = 1000;
  double amplitude = 0.5;
  double sweepStartHz = 20;
  double sweepEndHz = 20000;
  double sweepSeconds = 10;
  double _phase = 0;
  int _elapsed = 0;
  final math.Random _random = math.Random(0x5EED);
  final Float64List _pink = Float64List(7);

  void reset() {
    _phase = 0;
    _elapsed = 0;
    _pink.fillRange(0, 7, 0);
  }

  double _uniform() => _random.nextDouble() * 2 - 1;

  double _frequency() {
    if (waveform != Waveform.logSweep) return frequencyHz;
    final period = math.max(0.1, sweepSeconds);
    final t = (_elapsed / sampleRate) % period;
    return sweepStartHz * math.pow(sweepEndHz / sweepStartHz, t / period);
  }

  void fill(Float32List out) {
    final nyquist = sampleRate / 2;
    final amp = amplitude.clamp(0.0, 1.0);
    for (var i = 0; i < out.length; i++) {
      final freq = _frequency().clamp(0.0, nyquist);
      final double value;
      switch (waveform) {
        case Waveform.sine:
        case Waveform.logSweep:
          value = math.sin(2 * math.pi * _phase);
        case Waveform.square:
          value = _phase < 0.5 ? 1 : -1;
        case Waveform.sawtooth:
          value = 2 * _phase - 1;
        case Waveform.triangle:
          value = 1 - 4 * (_phase - 0.5).abs();
        case Waveform.whiteNoise:
          value = _uniform();
        case Waveform.pinkNoise:
          final white = _uniform();
          final b = _pink;
          b[0] = 0.99886 * b[0] + white * 0.0555179;
          b[1] = 0.99332 * b[1] + white * 0.0750759;
          b[2] = 0.96900 * b[2] + white * 0.1538520;
          b[3] = 0.86650 * b[3] + white * 0.3104856;
          b[4] = 0.55000 * b[4] + white * 0.5329522;
          b[5] = -0.7616 * b[5] - white * 0.0168980;
          final pink = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362;
          b[6] = white * 0.115926;
          value = pink * 0.11;
      }
      out[i] = value * amp;
      _phase = (_phase + freq / sampleRate) % 1.0;
      _elapsed++;
    }
  }

  /// Tệp WAV PCM 16-bit một kênh dài [seconds] giây để phát lặp.
  /// Sin/vuông/răng cưa/tam giác: làm tròn số chu kỳ để lặp không bị "tách".
  Uint8List renderWav(double seconds) {
    var frames = (seconds * sampleRate).round();
    if (waveform.index <= Waveform.triangle.index && frequencyHz > 0) {
      final cycles = math.max(1, (seconds * frequencyHz).round());
      frames = (cycles * sampleRate / frequencyHz).round();
    }
    reset();
    final samples = Float32List(frames);
    fill(samples);
    final data = ByteData(44 + frames * 2);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    final rate = sampleRate.round();
    ascii(0, 'RIFF');
    data.setUint32(4, 36 + frames * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, frames * 2, Endian.little);
    for (var i = 0; i < frames; i++) {
      data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
