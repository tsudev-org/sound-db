// QA-11 bước 3 (máy thật 25/11/2026, bản profile, tab Đo mức khi đang đo): 72-83 jiffies/s - luồng chính 58, raster 17.
// Hồ sơ CPU Dart 10 s: dựng/vẽ khung 51 % (dựng lại CẢ ListView mỗi nhịp 50 ms 32 %, lưới + nhãn đồ thị 2 phút vẽ lại mỗi
// khung 6,6 %), nhịp DSP 24 % trong đó FFT phổ 18 % - dù Đo mức không hiển thị phổ.
// Mỗi nhịp chỉ được dựng phần có số đổi, và chỉ phân tích phổ đủ nhịp khi trang Phân tích đang hiển thị.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/theme/tokens.g.dart';
import 'package:sound_db/widgets/charts.dart';

import 'app_screens_test.dart' show services, tone;

Future<void> _vi(WidgetTester tester) async {
  tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
  tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

void main() {
  testWidgets('Đo mức: nhịp đo không dựng lại nút chọn, thẻ tĩnh - chỉ phần số đổi', (tester) async {
    await _vi(tester);
    final s = await tester.runAsync(services);
    final m = s!.measurement;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    for (var i = 0; i < 30; i++) {
      m.debugProcess(tone(1000, 0.1, 2400));
    }
    await tester.pumpAndSettle();

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (e, _) => rebuilt.add(e.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    m.debugProcess(tone(1000, 0.1, 2400));
    await tester.pump();
    debugOnRebuildDirtyWidget = null;

    expect(rebuilt.where((t) => t.startsWith('SegmentedButton')), isEmpty, reason: 'nút chọn trọng số dựng lại theo nhịp');
    expect(rebuilt.where((t) => t.startsWith('FilledButton') || t.startsWith('OutlinedButton')), isEmpty);
    // Trước sửa: cả ListView (~700 phần tử) mỗi nhịp.
    expect(rebuilt.length, lessThan(150), reason: 'nhịp đo dựng lại ${rebuilt.length} phần tử');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    m.dispose();
  });

  testWidgets('phổ chỉ phân tích đủ nhịp khi trang Phân tích hiển thị; phiên lưu vẫn có 1/3 octave', (tester) async {
    await _vi(tester);
    final s = await tester.runAsync(services);
    final m = s!.measurement;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();

    m.debugProcess(tone(1000, 0.1, 48000));
    expect(m.spectrumDemanded, isFalse);
    final before = m.spectrumAnalyses;
    for (var i = 0; i < 8; i++) {
      m.debugProcess(tone(1000, 0.1, 2400));
    }
    expect(m.spectrumAnalyses - before, 2, reason: 'Đo mức: phổ chỉ cần cho 1/3 octave của phiên - 5 lần/giây');
    final session = m.buildSession(label: 'x', deviceModel: 'test');
    expect(session?.thirdOctaveLzeq, isNotEmpty);

    await tester.tap(find.text('Phân tích').last);
    await tester.pumpAndSettle();
    expect(m.spectrumDemanded, isTrue);
    final shown = m.spectrumAnalyses;
    for (var i = 0; i < 4; i++) {
      m.debugProcess(tone(1000, 0.1, 2400));
    }
    expect(m.spectrumAnalyses - shown, 4);
    expect(m.peak?.frequencyHz, closeTo(1000, 5));
    expect(m.thirdOctave, isNotEmpty);

    await tester.tap(find.text('Đo mức').last);
    await tester.pumpAndSettle();
    expect(m.spectrumDemanded, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    m.dispose();
  });

  testWidgets('số đo hiển thị cập nhật 10 lần/giây (mỗi 2 nhịp), đồ thị theo cùng nhịp', (tester) async {
    // Vòng 2 (máy thật sau vòng 1: Đo mức 32-38 jiffies/s): khung vẽ còn 27 % CPU Dart, snapshot() + phân vị 5,6 %.
    // Trọng số F = 125 ms ⇒ hiển thị 10 lần/giây đủ; số đổi 20 lần/giây không đọc kịp.
    final s = await tester.runAsync(services);
    final m = s!.measurement;
    m.debugProcess(tone(1000, 0.1, 9600));
    final v0 = m.displayVersion;
    for (var i = 0; i < 8; i++) {
      m.debugProcess(tone(1000, 0.1, 2400));
    }
    expect(m.displayVersion - v0, 4);
    expect(m.snapshot, isNotNull);
    m.resetSession();
    expect(m.snapshot, isNull);
    expect(m.displayVersion - v0, 5, reason: 'xoá phiên phải làm mới số và đồ thị ngay');
    m.dispose();
  });

  test('đồ thị 2 phút chỉ vẽ lại khi có điểm mới', () {
    final values = [50.0, 60.0];
    final a = LevelHistoryPainter(values, SdbPalette.dark, version: 7);
    expect(a.shouldRepaint(LevelHistoryPainter(values, SdbPalette.dark, version: 7)), isFalse);
    expect(a.shouldRepaint(LevelHistoryPainter(values, SdbPalette.dark, version: 8)), isTrue);
  });
}
