import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Chân vùng bản ghi theo DATA_TABLE.md mục 3: TRÁI bộ chọn số bản ghi
/// (10/20/50/100/200, mặc định 10), GIỮA dòng tóm tắt, PHẢI phân trang.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.pageSize,
    required this.page,
    required this.total,
    required this.loading,
    required this.onPageSize,
    required this.onPage,
  });

  static const sizes = [10, 20, 50, 100, 200];

  /// Giá trị đọc từ kho được kiểm nằm trong bộ mốc; sai ⇒ 10 (mục 5).
  static int sanitize(int? value) => sizes.contains(value) ? value! : 10;

  /// Đổi mốc giữ bản ghi đầu đang nhìn thấy (mục 4).
  static int pageAfterResize(int page, int oldSize, int newSize) => ((page - 1) * oldSize) ~/ newSize + 1;

  final int pageSize;
  final int page;
  final int total;
  final bool loading;
  final ValueChanged<int> onPageSize;
  final ValueChanged<int> onPage;

  int get pages => total == 0 ? 1 : (total + pageSize - 1) ~/ pageSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = total == 0 ? 0 : (page - 1) * pageSize + 1;
    final last = (page * pageSize).clamp(0, total);
    final muted = TextStyle(color: p.textMuted, fontSize: 13);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 480 ? SdbSpacing.s2 : SdbSpacing.s4),
      decoration: BoxDecoration(
        color: p.bgSubtle,
        border: Border(top: BorderSide(color: p.border)),
      ),
      // Hẹp (điện thoại 360 px trong thẻ): bỏ chữ "/ trang" và thu nút mũi tên để không tràn ngang.
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 340;
          final arrow = compact ? const BoxConstraints.tightFor(width: 36, height: 36) : null;
          return Row(
            children: [
              SizedBox(
                height: 32,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s2),
                    decoration: BoxDecoration(
                      color: p.bgSurface,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(SdbRadius.md),
                    ),
                    child: DropdownButton<int>(
                      value: pageSize,
                      isDense: true,
                      onChanged: loading ? null : (v) => onPageSize(v!),
                      items: [for (final s in sizes) DropdownMenuItem(value: s, child: Text('$s'))],
                    ),
                  ),
                ),
              ),
              if (!compact) ...[const SizedBox(width: SdbSpacing.s2), Text(context.l10n.perPage, style: muted)],
              Expanded(
                child: Center(
                  child: Text('$first-$last / $total', style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.previousPage,
                constraints: arrow,
                padding: compact ? EdgeInsets.zero : null,
                onPressed: loading || page <= 1 ? null : () => onPage(page - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$page / $pages', style: muted),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.nextPage,
                constraints: arrow,
                padding: compact ? EdgeInsets.zero : null,
                onPressed: loading || page >= pages ? null : () => onPage(page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          );
        },
      ),
    );
  }
}
