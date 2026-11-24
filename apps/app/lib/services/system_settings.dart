import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mở trang cài đặt của app trong hệ điều hành (QA-10: quyền micro bị từ chối "không hỏi lại").
/// Chỉ Android có kênh gốc (`MainActivity.kt`); nền tảng khác trả `false` để giao diện ẩn nút.
class SystemSettings {
  static const _channel = MethodChannel('com.tsudev.sounddb/system');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> openAppSettings() async {
    if (!supported) return false;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
