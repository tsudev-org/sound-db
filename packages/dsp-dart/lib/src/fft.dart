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
      // k ngoài, start trong: hệ số xoay đọc một lần cho mọi nhóm (QA-11 bước 4). Mỗi cánh bướm độc lập ⇒ cùng kết quả.
      for (var k = 0; k < half; k++) {
        final wr = _cos[k * step];
        final wi = _sin[k * step];
        for (var start = 0; start < n; start += len) {
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

/// FFT cho tín hiệu THỰC độ dài [size] bằng một FFT phức [size]/2 (gói mẫu chẵn/lẻ vào phần thực/ảo rồi tách) - nhanh
/// gần gấp đôi [Fft] cho cùng kết quả (lệch cỡ sai số làm tròn, xem test/qa11_block_rfft_test.dart). QA-11 bước 4.
class RealFft {
  RealFft(this.size)
    : assert(size >= 4 && (size & (size - 1)) == 0, 'kích thước FFT phải là lũy thừa 2'),
      _half = Fft(size ~/ 2),
      _zr = Float64List(size ~/ 2),
      _zi = Float64List(size ~/ 2),
      _wr = Float64List(size ~/ 2 + 1),
      _wi = Float64List(size ~/ 2 + 1) {
    for (var k = 0; k <= size ~/ 2; k++) {
      final angle = -2 * math.pi * k / size;
      _wr[k] = math.cos(angle);
      _wi[k] = math.sin(angle);
    }
  }

  final int size;
  final Fft _half;
  final Float64List _zr, _zi, _wr, _wi;

  /// Số bin một phía (0..N/2).
  int get bins => size ~/ 2 + 1;

  /// Biến đổi thuận: [x] (độ dài [size]) ⇒ [re], [im] bin 0..N/2 (độ dài ≥ [bins]). [x] không bị sửa.
  void forward(Float64List x, Float64List re, Float64List im) {
    final h = size >> 1;
    final zr = _zr, zi = _zi;
    for (var n = 0; n < h; n++) {
      zr[n] = x[2 * n];
      zi[n] = x[2 * n + 1];
    }
    _half.transform(zr, zi);
    for (var k = 0; k <= h; k++) {
      final a = k == h ? 0 : k;
      final b = k == 0 ? 0 : h - k;
      // Z[k] và liên hợp của Z[h-k]: chẵn E = (Z[k] + Z*[h-k])/2, lẻ O = (Z[k] - Z*[h-k])/(2i).
      final pr = zr[a], pi = zi[a], qr = zr[b], qi = -zi[b];
      final er = 0.5 * (pr + qr), ei = 0.5 * (pi + qi);
      final or = 0.5 * (pi - qi), oi = -0.5 * (pr - qr);
      final wr = _wr[k], wi = _wi[k];
      re[k] = er + wr * or - wi * oi;
      im[k] = ei + wr * oi + wi * or;
    }
  }

  /// Biến đổi ngược của phổ Hermite: [re], [im] bin 0..N/2 ⇒ [out] (độ dài [size]), KHÔNG chia N (như [Fft.inverse]).
  void inverse(Float64List re, Float64List im, Float64List out) {
    final h = size >> 1;
    final zr = _zr, zi = _zi;
    for (var k = 0; k < h; k++) {
      // A = X[k] + X*[h-k] (mẫu chẵn), B = X[k] - X*[h-k] (mẫu lẻ, nhân e^{+2πik/N}); Z = A + iB·e^{iθ}.
      final xr = re[k], xi = im[k], yr = re[h - k], yi = -im[h - k];
      final ar = xr + yr, ai = xi + yi;
      final br = xr - yr, bi = xi - yi;
      final c = _wr[k], s = -_wi[k];
      final tr = br * c - bi * s, ti = br * s + bi * c;
      zr[k] = ar - ti;
      zi[k] = ai + tr;
    }
    _half.inverse(zr, zi);
    for (var n = 0; n < h; n++) {
      out[2 * n] = zr[n];
      out[2 * n + 1] = zi[n];
    }
  }
}
