// Dựng TOÀN BỘ app ở cỡ điện thoại và máy tính, đi qua mọi màn hình và tab, có dữ liệu đo thật.
// Mọi lỗi bố cục (tràn RenderFlex, ràng buộc vô hạn...) làm test đỏ.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/app_scope.dart';
import 'package:sound_db/data/database.dart';
import 'package:sound_db/services/measurement.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sound_db/sync/auth_service.dart';
import 'package:sound_db/sync/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Float32List tone(double hz, double amp, int n, {double fs = 48000}) =>
    Float32List.fromList([for (var i = 0; i < n; i++) amp * math.sin(2 * math.pi * hz * i / fs)]);

Future<AppServices> services() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Mỗi lượt một tệp riêng: inMemoryDatabasePath của sqflite_ffi dùng chung giữa các lần mở.
  final store = await LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-test').path}/db.sqlite');
  final settings = Settings(store);
  await settings.load();
  final auth = AuthService(settings);
  final sync = SyncService(store, auth, settings);
  return AppServices(
    store: store,
    settings: settings,
    measurement: MeasurementController(settings),
    auth: auth,
    sync: sync,
    deviceModel: 'Máy thử',
  );
}

/// SQLite (ffi) chạy trên luồng thật: bấm Tải lại và chờ trong runAsync rồi mới dựng lại khung.
Future<void> reload(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byTooltip('Tải lại'));
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [('điện thoại', const Size(390, 844)), ('máy tính', const Size(1280, 800))]) {
    testWidgets('mọi màn hình dựng được không lỗi bố cục - $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = await tester.runAsync(services);
      await tester.pumpWidget(SoundDbApp(services: s!));
      await tester.pumpAndSettle();
      expect(find.text('Đo mức âm'), findsWidgets);
      expect(find.textContaining('Chưa hiệu chuẩn'), findsOneWidget);

      // Có dữ liệu: 3 giây tông 1 kHz -20 dBFS.
      for (var i = 0; i < 6; i++) {
        s.measurement.debugProcess(tone(1000, 0.1, 24000));
      }
      await tester.pump();
      expect(find.text('LAF'), findsOneWidget);

      Future<void> go(String label) async {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await go('Phân tích');
      expect(find.text('Phân tích tần số'), findsOneWidget);
      expect(find.textContaining('1,000 kHz'), findsWidgets);
      await go('Phổ đồ');
      await go('Dải octave');
      await go('1/1 octave');
      await go('Công cụ');
      expect(find.text('Tần số & cao độ'), findsOneWidget);
      await go('Phát tín hiệu');
      await go('Ồn hồng');
      await go('Lịch sử');
      await reload(tester);
      expect(find.textContaining('Chưa có phiên đo nào'), findsOneWidget);
      expect(find.text('/ trang'), findsOneWidget);
      await go('Cài đặt');
      expect(find.textContaining('Đăng nhập tài khoản TsuDEV'), findsOneWidget);
      await go('Sáng');
      expect(s.settings.theme.name, 'light');
      await tester.tap(find.text('Hiệu chuẩn micro'));
      await tester.pumpAndSettle();
      expect(find.text('Đo 10 giây'), findsOneWidget);
      Navigator.of(tester.element(find.text('Đo 10 giây'))).pop();
      await tester.pumpAndSettle();

      // Lưu phiên rồi mở chi tiết từ Lịch sử.
      final session = s.measurement.buildSession(label: 'Phiên thử', deviceModel: 'Máy thử')!;
      await tester.runAsync(() => s.store.saveSession(session));
      // Biên độ 0,1 ⇒ 10 log10(0,005) = -23,01 dBFS; offset mặc định 120 ⇒ LZeq 96,99 dB.
      expect(session.summary['lzeq'], closeTo(96.99, 0.1));
      await go('Lịch sử');
      await reload(tester);
      expect(find.text('Phiên thử'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Phiên thử'));
        for (var i = 0; i < 20 && find.text('LAeq').evaluate().isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pump();
      expect(find.text('LAeq'), findsOneWidget);
      s.measurement.dispose();
    });
  }
}
