// tsudev-standards PRODUCT_POLICY mục 1.1 + 1.4: lần chạy đầu theo ngôn ngữ hệ thống (chưa hỗ trợ ⇒ tiếng Anh),
// lựa chọn trong Cài đặt thắng và có "Theo hệ thống"; máy đã cài bản chỉ tiếng Việt không đổi đột ngột.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/app_scope.dart';
import 'package:sound_db/core/format.dart';
import 'package:sound_db/data/database.dart';
import 'package:sound_db/l10n/l10n.dart';
import 'package:sound_db/pro/pro_service.dart';
import 'package:sound_db/services/measurement.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sound_db/sync/auth_service.dart';
import 'package:sound_db/sync/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<LocalStore> freshStore() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-l10n').path}/db.sqlite');
}

Future<AppServices> services(LocalStore store) async {
  final settings = Settings(store);
  await settings.load();
  final auth = AuthService(settings);
  final pro = ProService(store, auth, settings);
  return AppServices(
    store: store,
    settings: settings,
    measurement: MeasurementController(settings),
    auth: auth,
    sync: SyncService(store, auth, settings, pro),
    pro: pro,
    deviceModel: 'test',
  );
}

Map<String, Object?> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, Object?>;

/// Hộp thoại Pro lúc mở app đọc SQLite (ffi, luồng thật): cho nó chạy xong trước khi test kết thúc.
Future<void> drain(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pumpAndSettle();
}

void main() {
  test('ngôn ngữ hệ thống vi / en / ja ⇒ vi / en / en', () {
    expect(resolveAppLocale(const Locale('vi', 'VN')), const Locale('vi'));
    expect(resolveAppLocale(const Locale('en', 'GB')), const Locale('en'));
    expect(resolveAppLocale(const Locale('ja', 'JP')), const Locale('en'));
    expect(resolveAppLocale(null), const Locale('en'));
  });

  test('ARB vi và en có đúng cùng bộ khoá, không chuỗi rỗng', () {
    final vi = _arb('vi'), en = _arb('en');
    final keysVi = vi.keys.where((k) => !k.startsWith('@')).toSet();
    final keysEn = en.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keysEn, keysVi);
    for (final k in keysVi) {
      expect((vi[k] as String).trim(), isNotEmpty, reason: k);
      expect((en[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('máy mới: chưa lưu ngôn ngữ ⇒ theo hệ thống', () async {
    final s = Settings(await freshStore());
    await s.load();
    expect(s.localeCode, isNull);
    expect(s.locale, isNull);
  });

  test('máy đã cài bản chỉ tiếng Việt ⇒ giữ vi; chỉ di trú một lần; "Theo hệ thống" quay về null', () async {
    final store = await freshStore();
    await store.setValue('setting.defaults_v2', 'true');
    final s = Settings(store);
    await s.load();
    expect(s.localeCode, 'vi');
    await s.setLocaleCode(null);
    final again = Settings(store);
    await again.load();
    expect(again.localeCode, isNull);
    await again.setLocaleCode('en');
    final third = Settings(store);
    await third.load();
    expect(third.localeCode, 'en');
    await third.setLocaleCode('fr');
    expect(third.localeCode, isNull);
  });

  for (final (device, nav, title) in [
    (const Locale('vi', 'VN'), 'Đo mức', 'Đo mức âm'),
    (const Locale('en', 'US'), 'Meter', 'Sound level'),
    (const Locale('ja', 'JP'), 'Meter', 'Sound level'),
  ]) {
    testWidgets('khởi động máy mới với hệ thống ${device.toLanguageTag()} ⇒ giao diện "$title"', (tester) async {
      tester.platformDispatcher.localeTestValue = device;
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final s = (await tester.runAsync(() async => services(await freshStore())))!;
      await tester.pumpWidget(SoundDbApp(services: s));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.text(nav), findsWidgets);
      await drain(tester);
      s.measurement.dispose();
    });
  }

  testWidgets('lựa chọn đã lưu thắng ngôn ngữ hệ thống; số và ngày theo ngôn ngữ hiển thị', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final s = (await tester.runAsync(() async => services(await freshStore())))!;
    await tester.runAsync(() => s.settings.setLocaleCode('en'));
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    expect(find.text('Sound level'), findsWidgets);
    expect(formatNumber(1.5), '1.5');
    expect(formatDate(DateTime(2026, 11, 20)), '2026-11-20');

    await tester.runAsync(() => s.settings.setLocaleCode('vi'));
    await tester.pumpAndSettle();
    expect(find.text('Đo mức âm'), findsWidgets);
    expect(formatNumber(1.5), '1,5');
    expect(formatDate(DateTime(2026, 11, 20)), '20/11/2026');
    await drain(tester);
    s.measurement.dispose();
  });

  for (final (name, size) in [('điện thoại', const Size(360, 740)), ('máy tính', const Size(1280, 800))]) {
    testWidgets('mọi màn hình tiếng Anh không tràn bố cục - $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      final s = (await tester.runAsync(() async => services(await freshStore())))!;
      await tester.pumpWidget(SoundDbApp(services: s));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not calibrated'), findsOneWidget);
      Future<void> go(String label) async {
        await tester.ensureVisible(find.text(label).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      for (final label in ['Analysis', 'Spectrogram', 'Octave bands', 'Tools', 'Signal generator', 'Pink noise', 'History', 'Settings']) {
        await go(label);
      }
      expect(find.text('Sign in with TsuDEV account'), findsOneWidget);
      final list = find.ancestor(of: find.text('Sign in with TsuDEV account'), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text('System default'), 100, scrollable: list);
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      // Ô đăng nhập đã cuộn khỏi màn hình (ListView lười) ⇒ neo lại vào mục Ngôn ngữ đang hiện.
      final list2 = find.ancestor(of: find.text('System default'), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text('Microphone calibration'), -100, scrollable: list2);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Microphone calibration'));
      await tester.pumpAndSettle();
      expect(find.text('Measure 10 s'), findsOneWidget);
      await drain(tester);
      s.measurement.dispose();
    });
  }
}
