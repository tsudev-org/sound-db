// QA-05 (máy thật 23/11/2026): số đo bọc Semantics(liveRegion: true) với nhãn đổi mỗi 50 ms ⇒ 117 sự kiện trợ năng
// / ~5 s khi đang đo (2 khi tạm dừng), TalkBack đọc dồn liên tục, uiautomator "could not get idle state".
// Vùng live chỉ được báo khi VÙNG mức đổi (an toàn / lưu ý / nguy hại), không theo từng con số.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';

import 'app_screens_test.dart' show services, tone;

void main() {
  testWidgets('số đo không phải vùng live; vùng live chỉ mang tên vùng mức', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final handle = tester.ensureSemantics();
    final s = await tester.runAsync(services);
    await tester.pumpWidget(SoundDbApp(services: s!));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      s.measurement.debugProcess(tone(1000, 0.1, 24000));
    }
    await tester.pump();

    final live = <SemanticsNode>[];
    void walk(SemanticsNode n) {
      if (n.getSemanticsData().flagsCollection.isLiveRegion) live.add(n);
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
    final labels = [for (final n in live) n.getSemanticsData().label];
    expect(labels.where((l) => l.contains('đề-xi-ben')), isEmpty, reason: 'số đo đổi 20 lần/giây - không được là vùng live');
    // Tông 1 kHz biên độ 0,1 + offset mặc định ⇒ ~97 dB(A): vùng nguy hại.
    expect(labels, contains('Mức nguy hại'));
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    s.measurement.dispose();
  });
}
