// Bản Dart phải tái tạo đúng con số của bản tham chiếu Rust trên mọi vector
// trong conformance/vectors.json. Sinh lại vector:
//   cargo run -p sounddb-dsp --example gen_vectors > conformance/vectors.json
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:test/test.dart';

Float32List render(List<dynamic> tones, double seconds, double fs) {
  final n = (seconds * fs).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / fs;
    var v = 0.0;
    for (final tone in tones) {
      final pair = tone as List<dynamic>;
      v += (pair[1] as num).toDouble() * math.sin(2 * math.pi * (pair[0] as num).toDouble() * t);
    }
    out[i] = v;
  }
  return out;
}

double d(Object? v) => (v as num).toDouble();

void main() {
  final file = File('../../conformance/vectors.json');
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final tolDb = d(doc['tolerance_db']);
  final tolHz = d(doc['tolerance_hz_relative']);

  test('đáp ứng bộ lọc trọng số', () {
    for (final raw in doc['filters'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final w = Weighting.values.firstWhere((w) => w.label == c['weighting']);
      final filter = WeightingFilter(w, d(c['fs']));
      final freqs = c['freqs'] as List<dynamic>;
      final expected = c['response_db'] as List<dynamic>;
      for (var i = 0; i < freqs.length; i++) {
        expect(filter.responseDb(d(freqs[i])), closeTo(d(expected[i]), 1e-6), reason: '${c['weighting']} ${freqs[i]} Hz');
      }
    }
  });

  test('máy đo mức (61 số của ảnh chụp)', () {
    for (final raw in doc['meters'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final meter = SoundLevelMeter(d(c['fs']), d(c['offset_db']));
      meter.process(render(c['tones'] as List<dynamic>, d(c['seconds']), d(c['fs'])));
      final got = meter.snapshot().toFlat();
      final expected = c['snapshot'] as List<dynamic>;
      expect(got.length, expected.length);
      for (var i = 0; i < got.length; i++) {
        if (expected[i] == null) {
          expect(got[i].isFinite, isFalse, reason: 'chỉ số $i');
        } else {
          // Phân vị lượng tử 0,1 dB: lệch số học sát biên có thể nhảy một ô.
          final tol = (i >= 36 && i < 43) ? 0.1 + 1e-9 : tolDb;
          expect(got[i], closeTo(d(expected[i]), tol), reason: 'chỉ số $i');
        }
      }
    }
  });

  test('phổ: đỉnh và dải 1/3 octave', () {
    for (final raw in doc['spectra'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final window = switch (c['window']) {
        'hann' => WindowKind.hann,
        'blackman_harris' => WindowKind.blackmanHarris,
        _ => WindowKind.flatTop,
      };
      final size = c['size'] as int;
      final fs = d(c['fs']);
      final analyzer = SpectrumAnalyzer(size, fs, window, 0)..averaging = Averaging.none;
      analyzer.analyze(render(c['tones'] as List<dynamic>, size / fs, fs));
      final peak = analyzer.dominantPeak(20, 20000)!;
      expect(peak.frequencyHz, closeTo(d(c['peak_hz']), d(c['peak_hz']) * tolHz));
      expect(peak.levelDb, closeTo(d(c['peak_db']), tolDb));
      final bands = octaveBands(3, 20, 20000);
      expect([for (final b in bands) b.nominalHz], [for (final v in c['third_octave_nominal'] as List<dynamic>) d(v)]);
      final expected = c['third_octave_a_db'] as List<dynamic>;
      for (var i = 0; i < bands.length; i++) {
        expect(analyzer.bandLevelDb(bands[i].lowerHz, bands[i].upperHz, Weighting.a), closeTo(d(expected[i]), tolDb),
            reason: 'dải ${bands[i].nominalHz}');
      }
    }
  });

  test('cao độ', () {
    for (final raw in doc['pitches'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final fs = d(c['fs']);
      final size = c['size'] as int;
      final detector = PitchDetector(size, fs);
      final estimate = detector.detect(render(c['tones'] as List<dynamic>, size / fs, fs))!;
      expect(estimate.frequencyHz, closeTo(d(c['frequency_hz']), d(c['frequency_hz']) * tolHz));
      expect(estimate.clarity, closeTo(d(c['clarity']), 1e-6));
    }
  });

  test('tên nốt', () {
    expect(noteInfo(440, 440)!.name, 'A4');
    expect(noteInfo(261.63, 440)!.name, 'C4');
    expect(noteInfo(27.5, 440)!.name, 'A0');
  });

  test('WAV lặp có số chu kỳ nguyên', () {
    final g = SignalGenerator(48000)..frequencyHz = 1000;
    final wav = g.renderWav(1);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(ByteData.sublistView(wav).getUint32(40, Endian.little), 48000 * 2);
  });
}
