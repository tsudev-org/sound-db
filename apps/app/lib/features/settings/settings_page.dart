import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../sync/api_config.dart';
import '../../sync/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';
import 'calibration.dart';

const appVersion = String.fromEnvironment('SOUNDDB_VERSION', defaultValue: '26.11.1702');

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, services.auth, services.sync]),
        builder: (context, _) {
          final p = context.palette;
          Widget header(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(SdbSpacing.s4, SdbSpacing.s6, SdbSpacing.s4, SdbSpacing.s2),
                child: Text(text, style: TextStyle(color: p.textLink, fontWeight: FontWeight.w600)),
              );
          return ListView(children: [
            header('Tài khoản và đồng bộ'),
            const _AccountSection(),
            header('Hiệu chuẩn'),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Hiệu chuẩn micro'),
              subtitle: Text(settings.calibrated
                  ? 'Đã hiệu chuẩn · offset ${formatDb(settings.calibrationOffsetDb, digits: 2)}'
                  : 'Chưa hiệu chuẩn · dùng offset ước lượng ${formatDb(settings.calibrationOffsetDb, digits: 0)}'),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CalibrationPage())),
            ),
            header('Giao diện'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s4),
              child: SegmentedButton<ThemeChoice>(
                segments: const [
                  ButtonSegment(value: ThemeChoice.light, icon: Icon(Icons.light_mode_outlined), label: Text('Sáng')),
                  ButtonSegment(value: ThemeChoice.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Tối')),
                  ButtonSegment(value: ThemeChoice.system, icon: Icon(Icons.monitor_outlined), label: Text('Hệ thống')),
                ],
                selected: {settings.theme},
                onSelectionChanged: (v) => settings.setTheme(v.first),
              ),
            ),
            header('Đo lường'),
            SwitchListTile(
              title: const Text('Giữ màn hình sáng khi đang đo'),
              value: settings.keepScreenOn,
              onChanged: settings.setKeepScreenOn,
            ),
            ListTile(
              title: const Text('Tần số chuẩn A4'),
              subtitle: Text(formatHz(settings.a4Hz)),
              trailing: SizedBox(
                width: 200,
                child: Slider(min: 415, max: 466, divisions: 51, value: settings.a4Hz, onChanged: settings.setA4),
              ),
            ),
            header('Quyền riêng tư'),
            SwitchListTile(
              title: const Text('Chế độ ngoại tuyến hoàn toàn'),
              subtitle: const Text('Chặn mọi kết nối ra ngoài, kể cả đăng nhập và đồng bộ. Đo lường vẫn chạy đủ.'),
              value: settings.offlineMode,
              onChanged: settings.setOfflineMode,
            ),
            const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Âm thanh không bao giờ rời thiết bị'),
              subtitle: Text('Sound Db chỉ xử lý âm thanh trong bộ nhớ, không ghi âm. Khi đồng bộ, chỉ các con số đo được gửi đi.'),
            ),
            header('Giới thiệu'),
            ListTile(
              title: const Text('Sound Db'),
              subtitle: Text('Phiên bản $appVersion · Một sản phẩm của tsudev'),
              onTap: () => launchUrl(Uri.parse(apiBase), mode: LaunchMode.externalApplication),
            ),
            ListTile(
              title: const Text('tsudev.com'),
              onTap: () => launchUrl(Uri.parse('https://tsudev.com'), mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: SdbSpacing.s8),
          ]);
        },
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final auth = services.auth;
    final sync = services.sync;
    final p = context.palette;
    if (!auth.signedIn) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bạn đang dùng ở chế độ khách - mọi chức năng đo đều mở.', style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: SdbSpacing.s3),
          FilledButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    try {
                      await auth.signIn(deviceName: services.deviceModel);
                      await sync.syncNow();
                    } on AuthException catch (e) {
                      if (context.mounted) showMessage(context, e.message);
                    } catch (e) {
                      if (context.mounted) showMessage(context, 'Đăng nhập thất bại: $e');
                    }
                  },
            icon: const Icon(Icons.login),
            label: const Text('Đăng nhập tài khoản tsudev để đồng bộ lịch sử đo và hiệu chuẩn'),
          ),
          const SizedBox(height: SdbSpacing.s2),
          Text('Mở trình duyệt hệ thống tới tsudev.com (Google, GitHub hoặc tài khoản tsudev).',
              style: TextStyle(color: p.textMuted, fontSize: 12)),
        ]),
      );
    }
    final user = auth.user!;
    return Column(children: [
      ListTile(
        leading: CircleAvatar(
          backgroundColor: p.bgHover,
          child: Text(user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(), style: TextStyle(color: p.textPrimary)),
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
      ListTile(
        leading: sync.running
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync),
        title: const Text('Đồng bộ ngay'),
        subtitle: Text(sync.statusText),
        onTap: sync.running ? null : () => sync.syncNow(),
      ),
      SwitchListTile(
        title: const Text('Tự đồng bộ khi mở app và sau khi lưu'),
        value: services.settings.autoSync,
        onChanged: services.settings.setAutoSync,
      ),
      ListTile(
        leading: const Icon(Icons.devices_outlined),
        title: const Text('Quản lý thiết bị và dữ liệu trên web'),
        onTap: () => launchUrl(Uri.parse('$apiBase/bang-dieu-khien/'), mode: LaunchMode.externalApplication),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Đăng xuất'),
        onTap: () async {
          await auth.signOut();
          await sync.resetCursor();
        },
      ),
      ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: p.danger),
        title: const Text('Đăng xuất và xóa dữ liệu cục bộ'),
        subtitle: const Text('Xóa lịch sử, hiệu chuẩn và cài đặt trên máy này. Dữ liệu đã đồng bộ vẫn còn trên tài khoản.'),
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xóa dữ liệu trên máy này?'),
              content: const Text('Bản ghi chưa đồng bộ sẽ mất vĩnh viễn.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
              ],
            ),
          );
          if (ok != true) return;
          await auth.signOut();
          await services.store.wipe();
          await services.settings.load();
        },
      ),
    ]);
  }
}
