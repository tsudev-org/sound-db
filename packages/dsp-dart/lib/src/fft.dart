import 'dart:math' as math;
import 'dart:typed_data';

/// FFT phức cơ số 2 tại chỗ, bảng hệ số xoay tính sẵn.
class Fft {
  Fft(this.size)
      : assert(size >= 2 && (size & (size - 1)) == 0, 'kích thước FFT phải là lũy thừa 2'),
        _cos = Float64List(size ~/ 2),
        _sin = Float64List(size ~/ 2),
        _rev = Int32List(size) {
    for (var i = 0; i < size ~/ 2; i++) {
      final angle = -2 * math.pi * i / size;
      _cos[i] = math.cos(angle);
      _sin[i] = math.sin(angle);
    }
    final bits = size.bitLength - 1;
    for (var i = 0; i < size; i++) {
      var reversed = 0;
      var value = i;
      for (var b = 0; b < bits; b++) {
        reversed = (reversed << 1) | (value & 1);
        value >>= 1;
      }
      _rev[i] = reversed;
    }
  }

  final int size;
  final Float64List _cos;
  final Float64List _sin;
  final Int32List _rev;

  /// Biến đổi thuận tại chỗ trên (re, im).
  void transform(Float64List re, Float64List im) {
    final n = size;
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var start = 0; start < n; start += len) {
        for (var k = 0; k < half; k++) {
          final wr = _cos[k * step];
          final wi = _sin[k * step];
          final a = start + k;
          final b = a + half;
          final xr = re[b] * wr - im[b] * wi;
          final xi = re[b] * wi + im[b] * wr;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
        }
      }
    }
  }

  /// Biến đổi ngược (không chia N - người gọi tự chuẩn hóa).
  void inverse(Float64List re, Float64List im) {
    for (var i = 0; i < size; i++) {
      im[i] = -im[i];
    }
    transform(re, im);
    for (var i = 0; i < size; i++) {
      im[i] = -im[i];
    }
  }
}
