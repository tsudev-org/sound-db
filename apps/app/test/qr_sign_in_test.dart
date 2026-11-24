// QR3 (tsudev-standards CROSS_DEVICE_LOGIN v1.1.0, phiếu 20261124-QR1): màn đăng nhập thống nhất + "Quét để đăng nhập"
// (Đ1). Bộ quét chỉ nhận đúng mã QR của tsudev (T9); mã Đ2 (cho phép thiết bị khác) không làm ở app này (ADR-0003).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/app.dart';
import 'package:sound_db/features/account/xd_scan.dart';

import 'app_screens_test.dart' show services;

const _id = 'AbCdEfGhIjKlMnOpQrStUv'; // 22 ký tự
const _k = 'aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789-_aBcDe'; // 43 ký tự

void main() {
  group('XdScan.classify (T9)', () {
    test('Đ1 hợp lệ ⇒ mở đúng URL /x/<id>, giữ bí mật sau #', () {
      final r = XdScan.classify('https://tsudev.com/x/$_id?f=d#$_k');
      expect(r, isA<XdSignIn>());
      final uri = (r as XdSignIn).uri;
      expect(uri.host, 'tsudev.com');
      expect(uri.path, '/x/$_id');
      expect(uri.fragment, _k);
    });
    test('Đ2 (f=k) ⇒ hướng sang app tsudev đã đăng nhập, không mở', () {
      expect(XdScan.classify('https://tsudev.com/x/$_id?f=k#$_k'), isA<XdApproveElsewhere>());
    });
    for (final bad in [
      'https://tsudev.com.evil.io/x/$_id?f=d#$_k',
      'http://tsudev.com/x/$_id?f=d#$_k',
      'https://tsudev.com:444/x/$_id?f=d#$_k',
      'https://user@tsudev.com/x/$_id?f=d#$_k',
      'https://tsudev.com/x/$_id?f=d&next=https://evil.io#$_k',
      'https://tsudev.com/y/$_id?f=d#$_k',
      'https://tsudev.com/x/$_id?f=d',
      'https://evil.io/?u=https://tsudev.com/x/$_id?f=d#$_k',
      'WIFI:S:quan-ca-phe;T:WPA;P:123;;',
    ]) {
      test('từ chối: $bad', () => expect(XdScan.classify(bad), isA<XdNotTsudev>()));
    }
  });

  Future<void> openSignIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final s = (await tester.runAsync(services))!;
    await tester.pumpWidget(SoundDbApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập tài khoản TsuDEV'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng tới Sound Db'), findsOneWidget);
    expect(find.text('Tiếp tục với tài khoản TsuDEV'), findsOneWidget);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('điện thoại (Android): màn đăng nhập có "Quét để đăng nhập"', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await openSignIn(tester);
    expect(find.text('Quét để đăng nhập'), findsOneWidget);
    await close(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('máy tính (Linux): không có lối quét (dùng Đ2 ở trang tsudev.com)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await openSignIn(tester);
    expect(find.text('Quét để đăng nhập'), findsNothing);
    await close(tester);
    debugDefaultTargetPlatformOverride = null;
  });
}
