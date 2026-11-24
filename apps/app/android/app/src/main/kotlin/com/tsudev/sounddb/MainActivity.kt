package com.tsudev.sounddb

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // QA-10: quyền micro bị từ chối "không hỏi lại" ⇒ mở trang thông tin ứng dụng để người dùng tự cấp quyền.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tsudev.sounddb/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
