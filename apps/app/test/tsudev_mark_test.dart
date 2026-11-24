// BRAND_ASSETS 4.1.0 (tsudev-standards v5.1.0): mọi liên kết tới tsudev.com có dấu hiệu TsuDEV (>= 16 px, nhãn "TsuDEV").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/widgets/common.dart';

import 'app_screens_test.dart' show services;

void main() {
  testWidgets('Cài đặt: liên kết tsudev.com có dấu hiệu TsuDEV đứng trước', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final s = (await tester.runAsync(services))!;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('tsudev.com'), 300, scrollable: find.byType(Scrollable).last);
    final tile = find.widgetWithText(ListTile, 'tsudev.com');
    final mark = find.descendant(of: tile, matching: find.byType(TsuDevMark));
    expect(mark, findsOneWidget);
    expect(tester.getSize(mark).width, greaterThanOrEqualTo(16));
    expect(tester.getTopLeft(mark).dx, lessThan(tester.getTopLeft(find.text('tsudev.com')).dx), reason: 'dấu đứng TRƯỚC chữ');
    expect(find.bySemanticsLabel('TsuDEV'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
