import 'package:flutter/material.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../pro/pro_page.dart';
import '../../sync/api_config.dart';
import '../../sync/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';
import 'calibration.dart';

const appVersion = String.fromEnvironment('SOUNDDB_VERSION', defaultValue: '26.11.2301');

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, services.auth, services.sync, services.pro]),
        builder: (context, _) {
          final p = context.palette;
          final l = context.l10n;
          Widget header(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(SdbSpacing.s4, SdbSpacing.s6, SdbSpacing.s4, SdbSpacing.s2),
                child: Text(text, style: TextStyle(color: p.textLink, fontWeight: FontWeight.w600)),
              );
          return ListView(children: [
            header(l.sectionAccount),
            const _AccountSection(),
            header(l.sectionCalibration),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l.micCalibration),
              subtitle: Text(settings.calibrated
                  ? l.calibratedOffset(formatDb(settings.calibrationOffsetDb, digits: 2))
                  : l.notCalibratedOffset(formatDb(settings.calibrationOffsetDb, digits: 0))),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CalibrationPage())),
            ),
            header(l.sectionTheme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s4),
              child: SegmentedButton<ThemeChoice>(
                segments: [
                  ButtonSegment(value: ThemeChoice.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.themeLight)),
                  ButtonSegment(value: ThemeChoice.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.themeDark)),
                  ButtonSegment(value: ThemeChoice.system, icon: const Icon(Icons.monitor_outlined), label: Text(l.themeSystem)),
                ],
                selected: {settings.theme},
                onSelectionChanged: (v) => settings.setTheme(v.first),
              ),
            ),
            header(l.sectionLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s4),
              // Tên ngôn ngữ viết bằng chính ngôn ngữ đó (không dịch) để ai cũng tìm được.
              child: SegmentedButton<String>(
                key: const Key('language-choice'),
                segments: [
                  ButtonSegment(value: '', label: Text(l.languageSystem)),
                  const ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
                  const ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.localeCode ?? ''},
                onSelectionChanged: (v) => settings.setLocaleCode(v.first.isEmpty ? null : v.first),
              ),
            ),
            header(l.sectionMeasurement),
            SwitchListTile(
              title: Text(l.keepScreenOn),
              value: settings.keepScreenOn,
              onChanged: settings.setKeepScreenOn,
            ),
            ListTile(
              title: Text(l.a4Reference),
              subtitle: Text(formatHz(settings.a4Hz)),
              trailing: SizedBox(
                width: 200,
                child: Slider(min: 415, max: 466, divisions: 51, value: settings.a4Hz, onChanged: settings.setA4),
              ),
            ),
            header(l.sectionPrivacy),
            SwitchListTile(
              title: Text(l.offlineMode),
              subtitle: Text(l.offlineModeHint),
              value: settings.offlineMode,
              onChanged: settings.setOfflineMode,
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(l.audioNeverLeaves),
              subtitle: Text(l.audioNeverLeavesHint),
            ),
            header(l.sectionAbout),
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/brand/icon-512.png', width: 40, height: 40, semanticLabel: l.logoSemantics),
              ),
              title: const Text('Sound Db'),
              subtitle: Text(l.versionLine(appVersion)),
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

/// Ô trạng thái TsuDEV Pro, mở màn Pro / Ủng hộ.
class _ProTile extends StatelessWidget {
  const _ProTile();

  @override
  Widget build(BuildContext context) {
    final pro = AppScope.of(context).pro;
    final until = pro.proUntil;
    final l = context.l10n;
    final date = until == null ? '' : formatDate(until.toLocal());
    return ListTile(
      key: const Key('pro-tile'),
      leading: const Icon(Icons.workspace_premium_outlined),
      title: Text(pro.isPro ? l.proUntil(date) : l.freePlan),
      subtitle: Text(pro.isPro
          ? l.proTileOn
          : l.proTileOff),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProPage())),
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
    final l = context.l10n;
    if (!auth.signedIn) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.guestMode, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: SdbSpacing.s3),
          FilledButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    try {
                      await auth.signIn(deviceName: services.deviceModel);
                      await services.pro.refresh();
                      await sync.syncNow();
                    } on AuthException catch (e) {
                      if (context.mounted) showMessage(context, e.message);
                    } catch (e) {
                      if (context.mounted) showMessage(context, l.signInFailed('$e'));
                    }
                  },
            icon: const Icon(Icons.login),
            label: Text(l.signInButton),
          ),
          const SizedBox(height: SdbSpacing.s2),
          Text(l.signInHint,
              style: TextStyle(color: p.textMuted, fontSize: 12)),
          const SizedBox(height: SdbSpacing.s2),
          const _ProTile(),
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
        title: TsuNameWithBadge(name: user.name, badge: services.pro.state.badge),
        subtitle: Text(user.email),
      ),
      const _ProTile(),
      ListTile(
        leading: sync.running
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync),
        title: Text(l.syncNow),
        subtitle: Text(sync.statusText),
        onTap: sync.running ? null : () => sync.syncNow(),
      ),
      SwitchListTile(
        title: Text(l.autoSync),
        value: services.settings.autoSync,
        onChanged: services.settings.setAutoSync,
      ),
      ListTile(
        leading: const Icon(Icons.devices_outlined),
        title: Text(l.manageOnWeb),
        onTap: () => launchUrl(Uri.parse('$apiBase${l.localeName == 'en' ? '/en' : ''}/bang-dieu-khien/'), mode: LaunchMode.externalApplication),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l.signOut),
        onTap: () async {
          await auth.signOut();
          await services.pro.clear();
          await sync.resetCursor();
        },
      ),
      ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: p.danger),
        title: Text(l.signOutWipe),
        subtitle: Text(l.signOutWipeHint),
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l.wipeConfirmTitle),
              content: Text(l.wipeConfirmBody),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
              ],
            ),
          );
          if (ok != true) return;
          await auth.signOut();
          await services.pro.clear();
          await services.store.wipe();
          await services.settings.load();
        },
      ),
    ]);
  }
}
