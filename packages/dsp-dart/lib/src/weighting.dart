import 'dart:math' as math;

/// Tần số cực IEC 61672-1 phụ lục E (Hz).
const double f1 = 20.598997057568145;
const double f2 = 107.6526465527343;
const double f3 = 737.8622346645901;
const double f4 = 12194.217147998012;

enum Weighting {
  a('A'),
  c('C'),
  z('Z');

  const Weighting(this.label);
  final String label;
}

double _log10(double x) => math.log(x) / math.ln10;

double _cRawDb(double f) {
  final f2s = f * f;
  return 20 * _log10(f4 * f4 * f2s / ((f2s + f1 * f1) * (f2s + f4 * f4)));
}

double _aRawDb(double f) {
  final fs = f * f;
  final num = f4 * f4 * fs * fs;
  final den = (fs + f1 * f1) * math.sqrt((fs + f2 * f2) * (fs + f3 * f3)) * (fs + f4 * f4);
  return 20 * _log10(num / den);
}

/// Đáp ứng analog chính xác (dB), 0 dB tại 1 kHz.
double analogGainDb(Weighting weighting, double freqHz) {
  if (freqHz <= 0) {
    return weighting == Weighting.z ? 0 : double.negativeInfinity;
  }
  switch (weighting) {
    case Weighting.z:
      return 0;
    case Weighting.c:
      return _cRawDb(freqHz) - _cRawDb(1000);
    case Weighting.a:
      return _aRawDb(freqHz) - _aRawDb(1000);
  }
}

class Biquad {
  Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  /// Biến đổi song tuyến tính của khâu analog (b0 s^2 + b1 s + b2)/(a0 s^2 + a1 s + a2).
  factory Biquad.fromAnalog(List<double> b, List<double> a, double sampleRate) {
    final k = 2 * sampleRate;
    final k2 = k * k;
    final na0 = a[0] * k2 + a[1] * k + a[2];
    return Biquad(
      (b[0] * k2 + b[1] * k + b[2]) / na0,
      (-2 * b[0] * k2 + 2 * b[2]) / na0,
      (b[0] * k2 - b[1] * k + b[2]) / na0,
      (-2 * a[0] * k2 + 2 * a[2]) / na0,
      (a[0] * k2 - a[1] * k + a[2]) / na0,
    );
  }

  /// Thông thấp bậc hai khớp biên độ (Vicanek 2016) - xem bản Rust.
  factory Biquad.matchedLowpass(double f0, double q, double sampleRate) {
    final w0 = 2 * math.pi * f0 / sampleRate;
    final zeta = 1 / (2 * q);
    double a1;
    double a2;
    if (zeta <= 1) {
      final damped = math.sqrt(1 - zeta * zeta) * w0;
      a1 = -2 * math.exp(-zeta * w0) * math.cos(damped);
    } else {
      final spread = math.sqrt(zeta * zeta - 1) * w0;
      a1 = -2 * math.exp(-zeta * w0) * (math.exp(spread) + math.exp(-spread)) / 2;
    }
    a2 = math.exp(-2 * zeta * w0);
    final bigA0 = math.pow(1 + a1 + a2, 2).toDouble();
    final bigA1 = math.pow(1 - a1 + a2, 2).toDouble();
    final bigA2 = -4 * a2;
    final phi1 = math.pow(math.sin(w0 / 2), 2).toDouble();
    final phi0 = 1 - phi1;
    final phi2 = 4 * phi0 * phi1;
    final r1 = (bigA0 * phi0 + bigA1 * phi1 + bigA2 * phi2) * q * q;
    final bigB0 = bigA0;
    final bigB1 = math.max(0.0, (r1 - bigB0 * phi0) / phi1);
    final b0 = 0.5 * (math.sqrt(bigB0) + math.sqrt(bigB1));
    final b1 = math.sqrt(bigB0) - b0;
    return Biquad(b0, b1, 0, a1, a2);
  }

  final double b0, b1, b2, a1, a2;
  double _z1 = 0, _z2 = 0;

  double process(double x) {
    final y = b0 * x + _z1;
    _z1 = b1 * x - a1 * y + _z2;
    _z2 = b2 * x - a2 * y;
    return y;
  }

  double magnitude(double freqHz, double sampleRate) {
    final w = 2 * math.pi * freqHz / sampleRate;
    final c1 = math.cos(w), s1 = math.sin(w), c2 = math.cos(2 * w), s2 = math.sin(2 * w);
    final nr = b0 + b1 * c1 + b2 * c2;
    final ni = -(b1 * s1 + b2 * s2);
    final dr = 1 + a1 * c1 + a2 * c2;
    final di = -(a1 * s1 + a2 * s2);
    return math.sqrt((nr * nr + ni * ni) / (dr * dr + di * di));
  }

  void reset() {
    _z1 = 0;
    _z2 = 0;
  }
}

/// Bộ lọc trọng số miền thời gian (giống `Cascade` của bản Rust).
class WeightingFilter {
  WeightingFilter(this.weighting, this.sampleRate) {
    final w1 = 2 * math.pi * f1;
    final w2 = 2 * math.pi * f2;
    final w3 = 2 * math.pi * f3;
    final hp1 = Biquad.fromAnalog([1, 0, 0], [1, 2 * w1, w1 * w1], sampleRate);
    final lp4 = Biquad.matchedLowpass(f4, 0.5, sampleRate);
    switch (weighting) {
      case Weighting.z:
        break;
      case Weighting.c:
        _sections.addAll([hp1, lp4]);
      case Weighting.a:
        _sections.addAll([hp1, Biquad.fromAnalog([1, 0, 0], [1, w2 + w3, w2 * w3], sampleRate), lp4]);
    }
    final at1k = _rawMagnitude(1000);
    _gain = at1k > 0 ? 1 / at1k : 1;
  }

  final Weighting weighting;
  final double sampleRate;
  final List<Biquad> _sections = [];
  double _gain = 1;

  double _rawMagnitude(double f) => _sections.fold(1.0, (acc, s) => acc * s.magnitude(f, sampleRate));

  double responseDb(double f) => 20 * _log10(_gain * _rawMagnitude(f));

  double process(double x) {
    var y = x * _gain;
    for (final section in _sections) {
      y = section.process(y);
    }
    return y;
  }

  void reset() {
    for (final section in _sections) {
      section.reset();
    }
  }
}
