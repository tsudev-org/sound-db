// Mặt đồng hồ `do-luong` (STD50 PR 2): vẽ được khi chưa đo (NaN), ở mức thường và vượt thang; giữ tỉ lệ 240:196.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/theme/app_theme.dart';
import 'package:sound_db/widgets/level_dial.dart';

void main() {
  for (final level in [double.nan, 0.0, 62.4, 85.0, 200.0]) {
    testWidgets('LevelDial vẽ không lỗi ở mức $level', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(body: Center(child: LevelDial(level: level, child: const Text('62,4')))),
      ));
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(LevelDial));
      expect(size.width, 300);
      expect(size.height, closeTo(300 * 196 / 240, 0.01));
      expect(find.text('62,4'), findsOneWidget);
    });
  }
}
