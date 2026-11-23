// QA-07 (24/11/2026, SM-M325FV): lưu phiên ở Đo mức rồi mở tab Lịch sử ⇒ vẫn "Chưa có phiên đo nào", 0-0 / 0, phải bấm
// Tải lại mới thấy. Tab Lịch sử nằm trong IndexedStack, chỉ tải một lần và chỉ nghe đồng bộ, không nghe kho cục bộ.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/data/database.dart';

import 'app_screens_test.dart' show services;

void main() {
  testWidgets('Lịch sử tự cập nhật khi kho cục bộ đổi (không cần Tải lại)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final s = (await tester.runAsync(services))!;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lịch sử').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có phiên đo nào'), findsOneWidget);

    await tester.runAsync(() async {
      await s.store.applyRemote(SyncRecord(kind: 'session', id: 'qa07', updatedAt: 1, deleted: false, data: {
        'v': 1,
        'started_at': '2026-11-24T06:18:00.000Z',
        'duration_s': 30,
        'label': 'Phiên vừa lưu',
        'note': '',
        'summary': {'laeq': 42.2},
        'series': {'interval_s': 1, 'laeq': [42.2]},
      }));
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Phiên vừa lưu'), findsOneWidget);
    expect(find.textContaining('Chưa có phiên đo nào'), findsNothing);
  });
}
