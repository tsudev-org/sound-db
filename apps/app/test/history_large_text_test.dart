// QA-08 (24/11/2026, SM-M325FV, font_scale 2.0 + bàn phím mở khi gõ tìm): thanh tìm/lọc cố định phía trên chiếm hết
// chiều cao thẻ, danh sách (Expanded) còn 0 px ⇒ kết quả không hiện, không cuộn tới được. Thanh lọc phải cuộn CÙNG
// danh sách.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/data/database.dart';

import 'app_screens_test.dart' show services;

void main() {
  testWidgets('chữ cỡ 2.0 + bàn phím mở: vẫn cuộn tới được kết quả Lịch sử', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 330); // bàn phím
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final s = (await tester.runAsync(services))!;
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await s.store.applyRemote(SyncRecord(kind: 'session', id: 'p$i', updatedAt: 1, deleted: false, data: {
          'v': 1,
          'started_at': '2026-11-2${i}T06:18:00.000Z',
          'duration_s': 30,
          'label': 'Phiên lớn $i',
          'note': '',
          'summary': {'laeq': 42.2},
          'series': {'interval_s': 1, 'laeq': [42.2]},
        }));
      }
    });
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    final list = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Phiên lớn 0'), 120, scrollable: list);
    expect(find.text('Phiên lớn 0').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
