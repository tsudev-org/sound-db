// Đo hiệu năng khung hình trên máy thật (phiếu 06 Phase 1, tiêu chí jank < 5% ở Đo mức và Phân tích).
// Chạy ở chế độ profile, quyền micro cấp trước:
//   adb shell pm grant com.tsudev.sounddb android.permission.RECORD_AUDIO
//   flutter drive --profile -d <serial> --driver test_driver/perf_driver.dart \
//     --target integration_test/perf_test.dart
// Kết quả: build/perf_*.json. Tự thu FrameTiming (không dùng watchPerformance: nó nối VM service trên máy để lấy GC
// và bị từ chối khi chạy qua adb Wi-Fi - đo 23/11/2026). Khung "giật" = build hoặc raster vượt ngân sách vsync.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sound_db/main.dart' as app;

const _doTrong = Duration(seconds: 30);

Future<void> _tapFirst(WidgetTester tester, List<String> labels) async {
  for (final l in labels) {
    final f = find.text(l);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
  }
  fail('Không thấy nút nào trong: $labels');
}

/// Chờ theo nhịp TỰ NHIÊN của app (chỉ vẽ khi có dữ liệu mới) - đúng trải nghiệm người dùng. Bản đầu ép pump mỗi
/// 16 ms cho ra cận trên nhân tạo: màn đứng yên cũng "giật" 26% vì chi phí nền vẽ lại toàn màn (đo 23/11/2026).
Future<void> _xem(WidgetTester tester, Duration d) => Future<void>.delayed(d);

Map<String, dynamic> _tomTat(List<FrameTiming> t, double hz) {
  final budgetUs = 1e6 / hz;
  double pct(List<int> v, double p) {
    if (v.isEmpty) return 0;
    final s = [...v]..sort();
    return s[((s.length - 1) * p).round()] / 1000;
  }

  final build = [for (final f in t) f.buildDuration.inMicroseconds];
  final raster = [for (final f in t) f.rasterDuration.inMicroseconds];
  final janky = t.where((f) => f.buildDuration.inMicroseconds > budgetUs || f.rasterDuration.inMicroseconds > budgetUs);
  return {
    'refresh_hz': hz,
    'budget_ms': budgetUs / 1000,
    'frames': t.length,
    'janky_frames': janky.length,
    'janky_percent': t.isEmpty ? 0 : 100 * janky.length / t.length,
    'build_p50_ms': pct(build, .5),
    'build_p90_ms': pct(build, .9),
    'build_p99_ms': pct(build, .99),
    'raster_p50_ms': pct(raster, .5),
    'raster_p90_ms': pct(raster, .9),
    'raster_p99_ms': pct(raster, .99),
  };
}

Future<Map<String, dynamic>> _do(WidgetTester tester, Duration d) async {
  final timings = <FrameTiming>[];
  void cb(List<FrameTiming> t) => timings.addAll(t);
  SchedulerBinding.instance.addTimingsCallback(cb);
  await _xem(tester, d);
  await _xem(tester, const Duration(milliseconds: 1500)); // engine gom FrameTiming tới ~1 s mới gửi
  SchedulerBinding.instance.removeTimingsCallback(cb);
  final hz = tester.view.display.refreshRate;
  return _tomTat(timings, hz > 0 ? hz : 60);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('hiệu năng khung hình: Đo mức + Phân tích khi đang đo', (tester) async {
    await app.main();
    await tester.pump(const Duration(seconds: 2));

    // Đối chứng: cùng màn, chưa đo (nội dung đứng yên nhưng vẫn ép vẽ khung) ⇒ tách chi phí nền của engine/GPU khỏi
    // chi phí của các painter.
    final nen = await _do(tester, const Duration(seconds: 15));

    await _tapFirst(tester, ['Bắt đầu đo', 'Start measuring']);
    await _xem(tester, const Duration(seconds: 2));

    final doMuc = await _do(tester, _doTrong);

    await _tapFirst(tester, ['Phân tích', 'Analysis']);
    await _xem(tester, const Duration(seconds: 2));
    final phanTich = await _do(tester, _doTrong);
    binding.reportData = {'perf_nen_chua_do': nen, 'perf_do_muc': doMuc, 'perf_phan_tich': phanTich};
    debugPrint('PERF nen_chua_do=$nen');
    debugPrint('PERF do_muc=$doMuc');
    debugPrint('PERF phan_tich=$phanTich');

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
