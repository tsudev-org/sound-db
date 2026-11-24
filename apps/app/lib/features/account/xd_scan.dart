import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tsudev_ui/tsudev_ui.dart';

import '../../l10n/l10n.dart';
import '../../services/system_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';

/// Kết quả đọc một mã QR khi đăng nhập chéo thiết bị (tsudev-standards CROSS_DEVICE_LOGIN v1.1.0).
sealed class XdScan {
  const XdScan();

  /// Kiểm bằng [TsuXdLink.parse] (T9: chỉ `https://tsudev.com/x/<id>?f=k|d#<bí mật>`, sai ⇒ KHÔNG mở liên kết).
  static XdScan classify(String raw) {
    final link = TsuXdLink.parse(raw);
    if (link == null) return const XdNotTsudev();
    return switch (link.flow) {
      // Đ1: máy đã đăng nhập hiện QR, app này là thiết bị mới ⇒ mở /x/<id> trong trình duyệt hệ thống.
      TsuXdFlow.push => XdSignIn(link.uri),
      // Đ2: máy mới hiện QR để máy đã đăng nhập Cho phép - Sound Db không giữ token tsudev (ADR-0003) nên không làm
      // vai xác nhận; hướng người dùng sang app tsudev đã đăng nhập.
      TsuXdFlow.pull => const XdApproveElsewhere(),
    };
  }
}

class XdNotTsudev extends XdScan {
  const XdNotTsudev();
}

class XdApproveElsewhere extends XdScan {
  const XdApproveElsewhere();
}

class XdSignIn extends XdScan {
  const XdSignIn(this.uri);
  final Uri uri;
}

/// Màn quét: quyền camera xin lúc mở màn này (tức lúc người dùng bấm "Quét để đăng nhập"), không lúc mở app.
/// Trả [Uri] của trang `/x/<id>` khi gặp mã Đ1 hợp lệ; mã sai chỉ báo, không mở gì.
class XdScanPage extends StatefulWidget {
  const XdScanPage({super.key});

  @override
  State<XdScanPage> createState() => _XdScanPageState();
}

class _XdScanPageState extends State<XdScanPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  String? _notice;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      switch (XdScan.classify(raw)) {
        case XdSignIn(:final uri):
          _done = true;
          Navigator.of(context).pop(uri);
          return;
        case XdApproveElsewhere():
          setState(() => _notice = context.l10n.xdApproveElsewhere);
        case XdNotTsudev():
          setState(() => _notice = context.l10n.xdNotTsudev);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l.xdScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SdbSpacing.s6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error.errorCode == MobileScannerErrorCode.permissionDenied ? l.xdCameraDenied : l.xdCameraError,
                        textAlign: TextAlign.center,
                      ),
                      if (error.errorCode == MobileScannerErrorCode.permissionDenied && SystemSettings.supported)
                        TextButton(onPressed: SystemSettings.openAppSettings, child: Text(l.openSettings)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: p.bgSurface,
            padding: const EdgeInsets.all(SdbSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.xdScanHint),
                if (_notice != null) ...[
                  const SizedBox(height: SdbSpacing.s2),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _notice!,
                      style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
