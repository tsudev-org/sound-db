import 'dart:math' as math;

/// Tỷ số octave hệ cơ số 10 (IEC 61260-1).
final double octaveRatio = math.pow(10, 0.3).toDouble();

const List<double> _nominalThird = [
  10, 12.5, 16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, //
  1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000,
];

class Band {
  const Band(this.nominalHz, this.centerHz, this.lowerHz, this.upperHz);
  final double nominalHz, centerHz, lowerHz, upperHz;

  String get label => nominalHz >= 1000
      ? '${(nominalHz / 1000).toStringAsFixed(nominalHz % 1000 == 0 ? 0 : 1)}k'
      : nominalHz.toStringAsFixed(nominalHz % 1 == 0 ? 0 : 1);
}

double nominalFrequency(double centerHz) {
  var best = _nominalThird.first;
  var bestErr = double.infinity;
  for (final candidate in _nominalThird) {
    final err = (math.log(candidate) - math.log(centerHz)).abs();
    if (err < bestErr) {
      bestErr = err;
      best = candidate;
    }
  }
  return best;
}

/// Dải 1/[fraction] octave (1 hoặc 3) có tần số danh định trong [minHz, maxHz].
List<Band> octaveBands(int fraction, double minHz, double maxHz) {
  assert(fraction == 1 || fraction == 3);
  final half = math.pow(octaveRatio, 1 / (2 * fraction)).toDouble();
  final (from, to) = fraction == 1 ? (-6, 4) : (-30, 13);
  final out = <Band>[];
  for (var x = from; x <= to; x++) {
    final center = 1000 * math.pow(octaveRatio, x / fraction).toDouble();
    final label = nominalFrequency(center);
    if (label < minHz || label > maxHz) continue;
    out.add(Band(label, center, center / half, center * half));
  }
  return out;
}
