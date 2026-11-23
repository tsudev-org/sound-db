// Lịch sử với 1200 phiên trên máy thật (phiếu 06 Phase 2: "1000+ bản ghi"). Bản release không có run-as và app chưa
// có nhập tệp ⇒ nạp qua integration_test trên bản profile (gói `.profile` riêng, không đụng dữ liệu thật):
//   flutter drive --profile -d <serial> --driver test_driver/perf_driver.dart \
//     --target integration_test/history_scale_test.dart
// Ghi build/history_scale.json: thời gian nạp, đếm, trang đầu/cuối, mở tab Lịch sử tới khi hiện đủ.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sound_db/data/database.dart';
import 'package:sound_db/data/models.dart';
import 'package:sound_db/main.dart' as app;

const _n = 1200;

MeasurementSession _phien(int i, DateTime t0) => MeasurementSession(
  id: 'scale-${i.toString().padLeft(5, '0')}',
  startedAt: t0.subtract(Duration(minutes: i)),
  durationSeconds: 60,
  label: i.isEven ? 'Phòng khách $i' : 'Đường phố có dấu ${'ăâđêôơư'[i % 7]} $i',
  note: '',
  summary: {'laeq': 40 + (i % 50).toDouble(), 'lafmax': 70},
  seriesLaeq: List.filled(60, 45),
  thirdOctaveLzeq: const {'1000': 40},
  calibrationOffsetDb: 120,
  deviceModel: 'scale',
  platform: 'android',
  updatedAt: t0,
  dirty: false,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lịch sử với $_n phiên', (tester) async {
    final store = await LocalStore.open();
    final t0 = DateTime.now();
    final sw = Stopwatch()..start();
    for (var i = 0; i < _n; i++) {
      await store.saveSession(_phien(i, t0));
    }
    final napMs = sw.elapsedMilliseconds;
    sw.reset();
    final dem = await store.countSessions();
    final demMs = sw.elapsedMilliseconds;
    sw.reset();
    final dau = await store.listSessions(limit: 100, offset: 0);
    final dauMs = sw.elapsedMilliseconds;
    sw.reset();
    final cuoi = await store.listSessions(limit: 100, offset: dem - 100);
    final cuoiMs = sw.elapsedMilliseconds;
    expect(dem, greaterThanOrEqualTo(_n));
    // Sắp mới nhất trước (cột started_at, QA-01): trang đầu là scale-00000, trang cuối có phiên cũ nhất.
    expect(dau.first.id, 'scale-00000');
    expect(cuoi.map((s) => s.id), contains('scale-${(_n - 1).toString().padLeft(5, '0')}'));

    await app.main();
    await tester.pump(const Duration(seconds: 2));
    sw.reset();
    await tester.tap(find.text('Lịch sử').last);
    var moMs = -1;
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('/ $dem').evaluate().isNotEmpty) {
        moMs = sw.elapsedMilliseconds;
        break;
      }
    }
    expect(moMs, isNonNegative, reason: 'Lịch sử phải hiện "1-10 / $dem"');
    expect(find.textContaining('Phòng khách 0'), findsOneWidget);

    binding.reportData = {
      'history_scale': {
        'sessions': dem,
        'insert_ms_total': napMs,
        'count_ms': demMs,
        'first_100_ms': dauMs,
        'last_100_ms': cuoiMs,
        'open_tab_ms': moMs,
      },
    };
    debugPrint('SCALE ${binding.reportData}');
  });
}
