import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../l10n/l10n.dart';
import '../../sync/auth_service.dart';
import '../../widgets/common.dart';
import 'xd_scan.dart';

/// Màn đăng nhập thống nhất (tsudev-standards AUTH_AND_ACCOUNT 13.2 + 13.4, CROSS_DEVICE_LOGIN v1.1.0).
///
/// Một lối vào thật: tài khoản TsuDEV (Google/GitHub/email chọn ở trang tsudev.com) - không gõ cứng nút nhà cung cấp.
/// "Quét để đăng nhập" (Đ1, chỉ điện thoại): quét QR trên máy tính đã đăng nhập ⇒ mở `https://tsudev.com/x/<id>` trong
/// trình duyệt hệ thống (trang đó lo Cho phép + email che + mã khớp) ⇒ đăng nhập OIDC như thường (ADR-0003, máy chủ
/// Sound Db giữ PKCE verifier và đổi mã) - phiên tsudev vừa tạo trong CÙNG trình duyệt nên tsudev trả mã ngay.
/// Trả `true` khi đã đăng nhập.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  /// Đ1 chỉ có trên thiết bị có camera sau (điện thoại); máy tính dùng Đ2 ở trang đăng nhập của tsudev.com.
  static bool get scanSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    final services = AppScope.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await services.auth.signIn(deviceName: services.deviceModel);
      await services.pro.refresh();
      await services.sync.syncNow();
      if (mounted && services.auth.signedIn) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, l.signInFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    final uri = await Navigator.of(context).push<Uri>(MaterialPageRoute(builder: (_) => const XdScanPage()));
    if (uri == null || !mounted) return;
    final l = context.l10n;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showMessage(context, l.signInFailed(uri.host));
      return;
    }
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.xdContinueTitle),
        content: Text(l.xdContinueBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.xdContinue)),
        ],
      ),
    );
    if (go == true) await _signIn();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void open(String path) => launchUrl(Uri.https('tsudev.com', path), mode: LaunchMode.externalApplication);
    return Scaffold(
      appBar: AppBar(),
      body: AbsorbPointer(
        absorbing: _busy,
        child: TsuSignInScreen(
          logo: Image.asset('assets/brand/icon-512.png', width: 48, height: 48, semanticLabel: 'Sound Db'),
          title: l.signInWelcome,
          tagline: l.signInTagline,
          primary: [
            TsuSignInOption(id: 'tsudev', label: l.signInWithTsudev, icon: const TsuDevMark(), onPressed: _signIn),
          ],
          onScanToSignIn: SignInPage.scanSupported ? _scan : null,
          onOpenTerms: () => open('/terms'),
          onOpenPrivacy: () => open('/privacy'),
          guestLabel: l.signInGuest,
          onGuest: () => Navigator.of(context).pop(false),
          guestNote: l.signInHint,
          locale: Localizations.localeOf(context),
        ),
      ),
    );
  }
}
