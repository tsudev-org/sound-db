// QA-06 (phiếu 06 mục 6): so độ nhạy thô của các nguồn thu Android trên CÙNG một âm ổn định (tông 1 kHz từ loa PC).
// Không đo mức tuyệt đối - chỉ chênh lệch giữa nguồn `unprocessed` (app dùng) với `mic`/`voiceRecognition` (gần đường
// thu của trình duyệt). Chạy ở chế độ profile, quyền micro cấp trước:
//   (test tự xin quyền micro - bấm Cho phép trên máy; flutter drive cài lại gói nên quyền cấp trước bị mất)
//   flutter drive --profile -d <serial> --driver test_driver/perf_driver.dart \
//     --target integration_test/mic_source_test.dart
// Kết quả: build/mic_source.json - mỗi nguồn: RMS toàn dải (dBFS) và mức riêng tại 1 kHz (Goertzel, dBFS sin).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:record/record.dart';

const _rate = 48000;
const _sources = [AndroidAudioSource.unprocessed, AndroidAudioSource.mic, AndroidAudioSource.voiceRecognition];

Future<Float32List> _record(AndroidAudioSource source, Duration d) async {
  final rec = AudioRecorder();
  final stream = await rec.startStream(
    RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _rate,
      numChannels: 1,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
      androidConfig: AndroidRecordConfig(audioSource: source),
    ),
  );
  final bytes = BytesBuilder(copy: false);
  final sub = stream.listen(bytes.add);
  await Future<void>.delayed(d);
  await sub.cancel();
  await rec.stop();
  await rec.dispose();
  final b = bytes.takeBytes();
  final bd = ByteData.sublistView(b);
  final n = b.length ~/ 2;
  // Bỏ 0,5 s đầu: bộ thu Android có đoạn khởi động (mẫu 0 / gain chưa ổn định).
  final skip = math.min(n, _rate ~/ 2);
  return Float32List.fromList([for (var i = skip; i < n; i++) bd.getInt16(i * 2, Endian.little) / 32768.0]);
}

double _db(double ms) => 10 * math.log(ms + 1e-20) / math.ln10;

double _rmsDb(Float32List x) {
  var s = 0.0;
  for (final v in x) {
    s += v * v;
  }
  return _db(s / x.length);
}

/// Mức sin tại [hz] (Goertzel trên toàn đoạn), dBFS theo quy ước RMS (sin biên độ 1 ⇒ -3,01 dB).
double _toneDb(Float32List x, double hz) {
  final w = 2 * math.pi * hz / _rate;
  final c = 2 * math.cos(w);
  var s1 = 0.0, s2 = 0.0;
  for (final v in x) {
    final s0 = v + c * s1 - s2;
    s2 = s1;
    s1 = s0;
  }
  final power = s1 * s1 + s2 * s2 - c * s1 * s2;
  final amp = 2 * math.sqrt(power) / x.length;
  return _db(amp * amp / 2);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QA-06: độ nhạy thô theo nguồn thu Android', (tester) async {
    // `flutter drive` cài lại gói ⇒ mất quyền đã cấp; xin lại (người chạy bấm Cho phép, hoặc tap qua adb).
    expect(await AudioRecorder().hasPermission(), isTrue, reason: 'chưa có quyền micro');
    final result = <String, List<Map<String, double>>>{};
    // Xen kẽ 3 vòng để âm nền trôi theo thời gian chia đều cho các nguồn.
    for (var round = 0; round < 3; round++) {
      for (final s in _sources) {
        final x = await _record(s, const Duration(seconds: 3));
        expect(x.length, greaterThan(_rate), reason: 'nguồn ${s.name} không trả mẫu');
        (result[s.name] ??= []).add({'rms_dbfs': _rmsDb(x), 'tone_1k_dbfs': _toneDb(x, 1000)});
      }
    }
    // ignore: avoid_print
    print('QA-06 $result');
    binding.reportData = {'mic_source': result};
  });
}
