import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/database.dart';
import 'pro/pro_service.dart';
import 'services/measurement.dart';
import 'services/settings.dart';
import 'sync/auth_service.dart';
import 'sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  final settings = Settings(store);
  await settings.load();
  final auth = AuthService(settings);
  await auth.load();
  final pro = ProService(store, auth, settings);
  await pro.load();
  final sync = SyncService(store, auth, settings, pro);
  await sync.load();
  final services = AppServices(
    store: store,
    settings: settings,
    measurement: MeasurementController(settings),
    auth: auth,
    sync: sync,
    pro: pro,
    deviceModel: await _deviceModel(),
  );
  runApp(SoundDbApp(services: services));
  // Làm mới quyền lợi Pro rồi đồng bộ khi mở app (không chặn giao diện, bỏ qua nếu khách/ngoại tuyến).
  // Hộp thoại nhắc Pro (7.3, 7.6) do HomeShell hiện sau khi quyền lợi đã làm mới.
  pro.refresh().whenComplete(() => sync.syncNow(onlyIfAuto: true));
}

Future<String> _deviceModel() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return '${a.manufacturer} ${a.model}';
    }
    if (Platform.isIOS) return (await info.iosInfo).utsname.machine;
    if (Platform.isMacOS) return (await info.macOsInfo).model;
    if (Platform.isWindows) return (await info.windowsInfo).productName;
    if (Platform.isLinux) return (await info.linuxInfo).prettyName;
  } catch (_) {}
  return Platform.operatingSystem;
}
