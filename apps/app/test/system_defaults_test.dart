// tsudev-standards PRODUCT_POLICY mục 1.2 + 1.4: giao diện lần chạy đầu theo hệ thống, máy đã cài không đổi đột ngột.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/data/database.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sound_db/theme/app_theme.dart';
import 'package:sound_db/theme/tokens.g.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<LocalStore> freshStore() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-t3').path}/db.sqlite');
}

void main() {
  test('chưa lưu lựa chọn ⇒ Hệ thống; lựa chọn đã lưu thắng', () {
    expect(ThemeChoice.parse(null), ThemeChoice.system);
    expect(ThemeChoice.parse('dark'), ThemeChoice.dark);
    expect(ThemeChoice.parse('warm'), ThemeChoice.light);
  });

  test('máy mới ⇒ Hệ thống', () async {
    final s = Settings(await freshStore());
    await s.load();
    expect(s.theme, ThemeChoice.system);
  });

  test('máy đã cài chưa từng chọn giao diện ⇒ giữ Tối, chỉ di trú một lần', () async {
    final store = await freshStore();
    await store.setValue('setting.fft_size', '4096');
    final s = Settings(store);
    await s.load();
    expect(s.theme, ThemeChoice.dark);
    await s.setTheme(ThemeChoice.system);
    final again = Settings(store);
    await again.load();
    expect(again.theme, ThemeChoice.system);
  });

  test('máy đã cài đã chọn Sáng ⇒ giữ Sáng', () async {
    final store = await freshStore();
    await store.setValue('setting.theme', 'light');
    final s = Settings(store);
    await s.load();
    expect(s.theme, ThemeChoice.light);
  });

  for (final brightness in Brightness.values) {
    testWidgets('hệ thống ${brightness.name} ⇒ đúng bảng màu', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeChoice.parse(null).mode,
        home: const Scaffold(),
      ));
      final ctx = tester.element(find.byType(Scaffold));
      expect(Theme.of(ctx).brightness, brightness);
      final palette = brightness == Brightness.dark ? SdbPalette.dark : SdbPalette.light;
      expect(Theme.of(ctx).scaffoldBackgroundColor, palette.bgBase);
    });
  }
}
