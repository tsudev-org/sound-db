// QA-11 (máy thật 25/11/2026): sau khi giảm DSP, khi đo ở tab Cài đặt app vẫn dùng ~0,75 lõi - luồng chính 55 %, raster
// 23 %, 19-21 khung/giây dù màn không đổi. Nguyên nhân: các trang ẩn của IndexedStack (Đo mức, Phân tích, Công cụ) nghe
// MeasurementController và dựng lại ở mỗi nhịp 50 ms ⇒ mỗi nhịp là một khung đầy đủ. Trang ẩn phải đứng yên.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/widgets/common.dart';

import 'app_screens_test.dart' show services, tone;

void main() {
  testWidgets('nhịp đo không xin khung khi chỉ trang ẩn nghe nó; hiện lại thì cập nhật', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final s = await tester.runAsync(services);
    final m = s!.measurement;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();

    // Ở Đo mức: nhịp đo phải xin khung (số đo đổi).
    m.debugProcess(tone(1000, 0.1, 24000));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      m.debugProcess(tone(1000, 0.1, 4800));
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'trang ẩn dựng lại theo nhịp đo (lần $i)');
    }

    // Quay lại Đo mức: số đo phải là số mới nhất, không phải số cũ lúc rời trang.
    await tester.tap(find.text('Đo mức').last);
    await tester.pumpAndSettle();
    expect(find.text('LAF'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    m.dispose();
  });

  testWidgets('VisibleListenableBuilder: ẩn thì không dựng, hiện lại dựng MỘT lần với giá trị mới nhất', (tester) async {
    final value = ValueNotifier(0);
    final enabled = ValueNotifier(true);
    var builds = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (context, on, _) => TickerMode(
          enabled: on,
          child: VisibleListenableBuilder(
            listenable: value,
            builder: (context, _) {
              builds++;
              return Text('${value.value}');
            },
          ),
        ),
      ),
    ));
    expect(find.text('0'), findsOneWidget);
    enabled.value = false;
    await tester.pump();
    final hiddenBuilds = builds;
    for (var i = 1; i <= 5; i++) {
      value.value = i;
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
    expect(builds, hiddenBuilds);
    enabled.value = true;
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
    expect(builds, hiddenBuilds + 1);
  });
}
