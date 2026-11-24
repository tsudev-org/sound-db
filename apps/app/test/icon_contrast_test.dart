// UI1 (24/11/2026, phiếu điều phối 20261124-UI1): biểu tượng menu Đo mức/Phân tích/Công cụ/Lịch sử/Cài đặt TRẮNG trên
// viên chỉ báo nhạt - ColorScheme thiếu secondaryContainer/onSecondaryContainer nên M3 vẽ icon đang chọn bằng onSecondary
// (trắng); rail thiếu selectedIconTheme. Chuẩn DESIGN_SYSTEM mục 1: biểu tượng trên NỀN THẬT ở MỌI trạng thái >= 3:1.
// Test đọc màu icon thực tế (IconTheme tại chỗ vẽ) và nền thực tế (viên chỉ báo phủ lên nền thanh).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/theme/app_theme.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Màu biểu tượng như mắt thấy: icon có thể bán trong suốt ⇒ phủ lên nền.
double iconContrast(Color icon, Color bg) => contrast(Color.alphaBlend(icon, bg), bg);

const _icons = [Icons.speed, Icons.graphic_eq, Icons.tune, Icons.history, Icons.settings];

Color _iconColor(WidgetTester tester, IconData icon, Finder within) {
  final f = find.descendant(of: within, matching: find.byIcon(icon));
  expect(f, findsOneWidget, reason: 'không thấy icon $icon');
  final widget = tester.widget<Icon>(f);
  return widget.color ?? IconTheme.of(tester.element(f)).color!;
}

void main() {
  for (final b in Brightness.values) {
    final theme = buildTheme(b);
    final name = b == Brightness.dark ? 'Tối' : 'Sáng';

    testWidgets('$name: NavigationBar - icon đang chọn và chưa chọn >= 3:1 trên nền thật', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: [for (final i in _icons) NavigationDestination(icon: Icon(i), label: '$i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = find.byType(NavigationBar);
      final barBg = theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surfaceContainer;
      final pill = Color.alphaBlend(
        theme.navigationBarTheme.indicatorColor ?? theme.colorScheme.secondaryContainer,
        barBg,
      );
      final selected = iconContrast(_iconColor(tester, _icons.first, bar), pill);
      expect(
        selected,
        greaterThanOrEqualTo(3),
        reason: 'icon ĐANG CHỌN trên viên chỉ báo: ${selected.toStringAsFixed(2)}:1',
      );
      for (final i in _icons.skip(1)) {
        final r = iconContrast(_iconColor(tester, i, bar), barBg);
        expect(r, greaterThanOrEqualTo(3), reason: 'icon chưa chọn $i: ${r.toStringAsFixed(2)}:1');
      }
    });

    testWidgets('$name: NavigationRail - icon đang chọn và chưa chọn >= 3:1 trên nền thật', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: 0,
                  labelType: NavigationRailLabelType.all,
                  destinations: [for (final i in _icons) NavigationRailDestination(icon: Icon(i), label: Text('$i'))],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rail = find.byType(NavigationRail);
      final railBg = theme.navigationRailTheme.backgroundColor ?? theme.colorScheme.surface;
      final pill = Color.alphaBlend(
        theme.navigationRailTheme.indicatorColor ?? theme.colorScheme.secondaryContainer,
        railBg,
      );
      final selected = iconContrast(_iconColor(tester, _icons.first, rail), pill);
      expect(selected, greaterThanOrEqualTo(3), reason: 'rail - icon ĐANG CHỌN: ${selected.toStringAsFixed(2)}:1');
      for (final i in _icons.skip(1)) {
        final r = iconContrast(_iconColor(tester, i, rail), railBg);
        expect(r, greaterThanOrEqualTo(3), reason: 'rail - icon chưa chọn $i: ${r.toStringAsFixed(2)}:1');
      }
    });

    test('$name: cặp container M3 (Chip chọn, FilledTonal, Badge...) đủ tương phản 4,5:1 cho chữ', () {
      final s = theme.colorScheme;
      for (final (label, fg, bg) in [
        ('secondaryContainer', s.onSecondaryContainer, s.secondaryContainer),
        ('primaryContainer', s.onPrimaryContainer, s.primaryContainer),
        ('tertiaryContainer', s.onTertiaryContainer, s.tertiaryContainer),
      ]) {
        final r = contrast(fg, bg);
        expect(r, greaterThanOrEqualTo(4.5), reason: '$label: ${r.toStringAsFixed(2)}:1');
      }
    });
  }
}
