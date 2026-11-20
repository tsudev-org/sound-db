import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/l10n/l10n.dart';
import 'package:sound_db/theme/app_theme.dart';
import 'package:sound_db/widgets/pagination_footer.dart';

void main() {
  test('chỉ nhận đúng bộ mốc chuẩn, sai thì về 10', () {
    expect(PaginationFooter.sanitize(50), 50);
    expect(PaginationFooter.sanitize(25), 10);
    expect(PaginationFooter.sanitize(null), 10);
  });

  test('đổi mốc giữ bản ghi đầu đang nhìn thấy', () {
    // Trang 5 cỡ 10 bắt đầu ở bản ghi thứ 41 ⇒ cỡ 20 phải là trang 3 (41-60).
    expect(PaginationFooter.pageAfterResize(5, 10, 20), 3);
    expect(PaginationFooter.pageAfterResize(3, 20, 10), 5);
  });

  testWidgets('chân bảng: bộ chọn trái, tóm tắt giữa, phân trang phải', (tester) async {
    int? picked;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: PaginationFooter(
          pageSize: 10,
          page: 2,
          total: 23,
          loading: false,
          onPageSize: (v) => picked = v,
          onPage: (_) {},
        ),
      ),
    ));
    expect(find.text('/ trang'), findsOneWidget);
    expect(find.text('11-20 / 23'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    final dropdownX = tester.getCenter(find.byType(DropdownButton<int>)).dx;
    final summaryX = tester.getCenter(find.text('11-20 / 23')).dx;
    final nextX = tester.getCenter(find.byTooltip('Trang sau')).dx;
    expect(dropdownX < summaryX && summaryX < nextX, isTrue);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50').last);
    await tester.pumpAndSettle();
    expect(picked, 50);
  });
}
