import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_scope.dart';
import 'features/analysis/analysis_page.dart';
import 'features/history/history_page.dart';
import 'features/meter/meter_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tools/tools_page.dart';
import 'pro/pro_page.dart';
import 'pro/pro_service.dart';
import 'theme/app_theme.dart';

class SoundDbApp extends StatelessWidget {
  const SoundDbApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) => MaterialApp(
          title: 'Sound Db',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: services.settings.theme.mode,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

const _destinations = [
  _Destination('Đo mức', Icons.speed_outlined, Icons.speed, MeterPage()),
  _Destination('Phân tích', Icons.graphic_eq_outlined, Icons.graphic_eq, AnalysisPage()),
  _Destination('Công cụ', Icons.tune_outlined, Icons.tune, ToolsPage()),
  _Destination('Lịch sử', Icons.history_outlined, Icons.history, HistoryPage()),
  _Destination('Cài đặt', Icons.settings_outlined, Icons.settings, SettingsPage()),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  AppLifecycleListener? _lifecycle;
  bool _noticeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _proNotices());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycle ??= AppLifecycleListener(onStateChange: (s) {
      final pro = AppScope.of(context).pro;
      pro.renewal.handleAppLifecycleState(s);
      // Quay lại sau ≥ 30 phút ở nền = lần mở mới (7.6): làm mới quyền lợi rồi xét nhắc.
      if (s == AppLifecycleState.resumed && pro.renewal.openPending) {
        pro.refresh().whenComplete(_proNotices);
      }
    });
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  void _openPro() {
    if (isPlayBuild) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProPage()));
    } else {
      launchUrl(proBuyUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Hộp thoại Pro ở màn chính sau khi mở app (PRODUCT_POLICY 7.6 rồi 7.3) - không bao giờ giữa lúc nhập liệu
  /// (`tsudev_ui` tự kiểm), mỗi lần tối đa một hộp thoại.
  Future<void> _proNotices() async {
    if (!mounted) return;
    final pro = AppScope.of(context).pro;
    final state = await pro.settled;
    if (!mounted) return;
    final renewal = await maybeShowProRenewal(context, controller: pro.renewal, state: state, onRenew: _openPro);
    if (renewal != null || _noticeChecked || !mounted) return;
    _noticeChecked = true;
    await maybeShowProNotice(
      context,
      controller: pro.notice,
      state: state,
      onSeePro: _openPro,
      // Sao lưu ra tệp (miễn phí): xuất CSV/JSON từ màn Lịch sử.
      onBackupToFile: () => setState(() => _index = 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = IndexedStack(index: _index, children: [for (final d in _destinations) d.page]);
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sound Db', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}
