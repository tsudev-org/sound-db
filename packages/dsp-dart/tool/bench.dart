// Đo chi phí từng khâu DSP cho QA-11 (CPU khi đo). Mô phỏng đúng nhịp của app
// (apps/app/lib/services/measurement.dart): mẫu 48 kHz đẩy theo khối, 20 nhịp hiển thị/giây.
//
// Chạy (AOT - gần bản release Flutter):
//   dart compile exe tool/bench.dart -o /tmp/sdb-bench && /tmp/sdb-bench [số giây]
// Kết quả là micro giây CPU cho MỖI GIÂY âm thanh; 1e6 = một lõi đầy.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sounddb_dsp/sounddb_dsp.dart';

void main(List<String> args) {
  final seconds = args.isEmpty ? 20 : int.parse(args.first);
  const fs = 48000.0;
  const block = 960; // 20 ms - cỡ khối thường gặp của bộ thu âm Android.
  final engine = Engine(sampleRate: fs);
  final rnd = math.Random(1);
  final audio = Float32List(fs.toInt());
  for (var i = 0; i < audio.length; i++) {
    audio[i] = (0.1 * math.sin(2 * math.pi * 440 * i / fs) + 0.02 * (rnd.nextDouble() * 2 - 1)).toDouble();
  }
  final spectrumDb = Float64List(engine.spectrum.bins);
  final peakHold = Float64List(engine.spectrum.bins);
  final watches = <String, Stopwatch>{};
  void timed(String name, void Function() f) {
    final sw = watches.putIfAbsent(name, Stopwatch.new)..start();
    f();
    sw.stop();
  }

  void runSecond() {
    for (var off = 0; off < audio.length; off += block) {
      final chunk = Float32List.sublistView(audio, off, off + block);
      timed('push (lọc A/C/Z mỗi mẫu)', () => engine.push(chunk));
    }
    for (var s = 0; s < 10; s++) {
      timed('snapshot 10/giây', () => engine.meter.snapshot());
    }
    for (var t = 0; t < 20; t++) {
      timed('analyzeSpectrum (FFT 8192)', engine.analyzeSpectrum);
      timed('spectrumDb x2', () {
        engine.spectrum.spectrumDb(Weighting.a, spectrumDb);
        engine.spectrum.spectrumDb(Weighting.a, peakHold, fromPeakHold: true);
      });
      timed('dominantPeak', () => engine.spectrum.dominantPeak(20, 20000));
      timed('detectPitch (NSDF)', engine.detectPitch);
      timed('bandLevels 1/3 + 1/1 + 1/3 Z', () {
        engine.bandLevels(3, Weighting.a);
        engine.bandLevels(1, Weighting.a);
        engine.bandLevels(3, Weighting.z);
      });
      timed('snapshot nhịp', () => engine.meter.snapshot());
    }
  }

  for (var i = 0; i < 3; i++) {
    runSecond(); // làm nóng
  }
  watches.clear();
  for (var i = 0; i < seconds; i++) {
    runSecond();
  }
  var total = 0;
  for (final e in watches.entries) {
    total += e.value.elapsedMicroseconds;
  }
  for (final e
      in (watches.entries.toList()..sort((a, b) => b.value.elapsedMicroseconds - a.value.elapsedMicroseconds))) {
    final us = e.value.elapsedMicroseconds / seconds;
    print(
      '${us.toStringAsFixed(0).padLeft(8)} µs/s  ${(100 * e.value.elapsedMicroseconds / total).toStringAsFixed(1).padLeft(5)} %  ${e.key}',
    );
  }
  print(
    '${(total / seconds).toStringAsFixed(0).padLeft(8)} µs/s  tổng (${(total / seconds / 1e4).toStringAsFixed(2)} % một lõi)',
  );
}
