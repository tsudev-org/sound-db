// QA-10 (24/11/2026, SM-M325FV): quyền micro bị từ chối "không hỏi lại" ⇒ banner lỗi bảo "cấp quyền trong cài đặt hệ
// thống" nhưng không có đường tới đó. Android phải có nút "Mở cài đặt" gọi kênh gốc mở trang thông tin ứng dụng.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart' show InputDevice;
import 'package:sound_db/app.dart';
import 'package:sound_db/app_scope.dart';
import 'package:sound_db/data/database.dart';
import 'package:sound_db/pro/pro_service.dart';
import 'package:sound_db/services/audio_input.dart';
import 'package:sound_db/services/measurement.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sound_db/sync/auth_service.dart';
import 'package:sound_db/sync/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _DeniedInput extends AudioInput {
  _DeniedInput() : super(sampleRate: 48000);
  @override
  Stream<Float32List> get samples => const Stream.empty();
  @override
  Future<void> start({InputDevice? device}) async =>
      throw AudioInputException('Sound Db cần quyền dùng micro để đo.', code: AudioInputException.permissionDenied);
  @override
  Future<void> stop() async {}
}

Future<AppServices> _services() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final store = await LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-perm').path}/db.sqlite');
  final settings = Settings(store);
  await settings.load();
  final auth = AuthService(settings);
  final pro = ProService(store, auth, settings);
  return AppServices(
    store: store,
    settings: settings,
    measurement: MeasurementController(settings, input: _DeniedInput()),
    auth: auth,
    sync: SyncService(store, auth, settings, pro),
    pro: pro,
    deviceModel: 'Máy thử',
  );
}

void main() {
  testWidgets('Android: quyền micro bị từ chối ⇒ banner có nút Mở cài đặt gọi kênh gốc', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.tsudev.sounddb/system'),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );

    final s = (await tester.runAsync(_services))!;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cần quyền dùng micro'), findsOneWidget);
    await tester.tap(find.text('Mở cài đặt'));
    await tester.pumpAndSettle();
    expect(calls, ['openAppSettings']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
    debugDefaultTargetPlatformOverride = null;
  });
}
