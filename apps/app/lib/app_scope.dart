import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'pro/pro_service.dart';
import 'services/measurement.dart';
import 'services/settings.dart';
import 'sync/auth_service.dart';
import 'sync/sync_service.dart';

/// Gói các dịch vụ dùng chung cho cây widget (không dùng thư viện quản lý
/// trạng thái ngoài: ít phụ thuộc = ít bề mặt chuỗi cung ứng).
class AppServices {
  AppServices({
    required this.store,
    required this.settings,
    required this.measurement,
    required this.auth,
    required this.sync,
    required this.pro,
    required this.deviceModel,
  });

  final LocalStore store;
  final Settings settings;
  final MeasurementController measurement;
  final AuthService auth;
  final SyncService sync;
  final ProService pro;
  final String deviceModel;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
