// QA-11 (máy thật 24/11/2026): khi đo, tiến trình dùng ~0,9 lõi CPU. Đo bằng packages/dsp-dart/tool/bench.dart: dò cao
// độ (FFT 8192 thuận + ngược) chạy 20 lần/giây ở MỌI tab, dù chỉ Bộ chỉnh âm hiển thị nó - các trang nằm trong
// IndexedStack nên luôn được gắn. Chỉ dò khi tab Bộ chỉnh âm đang hiển thị.
import 'package:flutter/widgets.dart' show Locale, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';

import 'app_screens_test.dart' show services, tone;

void main() {
  testWidgets('chỉ dò cao độ khi tab Bộ chỉnh âm đang hiển thị', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final s = await tester.runAsync(services);
    final m = s!.measurement;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();

    void feed() {
      for (var i = 0; i < 4; i++) {
        m.debugProcess(tone(440, 0.1, 4800));
      }
    }

    // Đo mức (mặc định): Bộ chỉnh âm được gắn trong IndexedStack nhưng ẩn.
    expect(m.pitchDemanded, isFalse);
    feed();
    expect(m.pitch, isNull, reason: 'không ai xem cao độ - không được dò');
    expect(m.snapshot, isNotNull, reason: 'mức âm vẫn phải cập nhật');

    await tester.tap(find.text('Công cụ').last);
    await tester.pumpAndSettle();
    expect(m.pitchDemanded, isTrue);
    feed();
    expect(m.pitch?.frequencyHz, closeTo(440, 1));

    await tester.tap(find.text('Đo mức').last);
    await tester.pumpAndSettle();
    expect(m.pitchDemanded, isFalse);
    expect(m.pitch, isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(m.pitchDemanded, isFalse, reason: 'gỡ cây widget phải nhả nhu cầu');
    m.dispose();
  });
}
