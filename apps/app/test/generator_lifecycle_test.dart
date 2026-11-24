// QA-09 (24/11/2026, SM-M325FV): Máy phát đang phát, ra màn hình chính rồi quay lại ⇒ âm đã dừng (Android tạm dừng
// trình phát) nhưng nút vẫn "Dừng phát" - giao diện lệch trạng thái thật. Máy phát phải TỰ dừng khi app ra nền (an
// toàn thính giác, lời cảnh báo ở đầu tab) và nút phải về "Phát".
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/features/tools/generator_tab.dart';
import 'package:sound_db/l10n/l10n.dart';
import 'package:sound_db/theme/app_theme.dart';

void main() {
  testWidgets('ra nền ⇒ máy phát dừng và nút về "Phát"', (tester) async {
    final calls = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        calls.add(call.method);
        return null;
      });
    }
    addTearDown(() {
      for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), null);
      }
    });

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.light),
      home: const Scaffold(body: GeneratorTab()),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Phát'), 200);
    await tester.tap(find.text('Phát'));
    await tester.pumpAndSettle();
    expect(find.text('Dừng phát'), findsOneWidget);
    calls.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(calls, anyOf(contains('stop'), contains('pause')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Phát'), findsOneWidget);
    expect(find.text('Dừng phát'), findsNothing);
  });
}
