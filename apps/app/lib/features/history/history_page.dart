import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/pagination_footer.dart';
import 'session_detail_page.dart';

/// Danh sách phiên đo đã lưu, phân trang từ kho (không tải hết rồi cắt). Tìm không dấu + lọc khoảng thời gian chạy
/// CÙNG một truy vấn với đếm và phân trang (SEARCH_AND_FILTER.md mục 6.3).
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _pageSizeKey = 'tsudev.pagesize.sessions';
  int _pageSize = 10;
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _failed = false;
  List<MeasurementSession> _rows = const [];
  bool _initialised = false;
  final _search = TextEditingController();
  Timer? _debounce;
  _Range _range = _Range.all;
  DateTimeRange? _custom;
  // Số thứ tự truy vấn: kết quả về muộn của truy vấn cũ không được đè kết quả mới (mục 2.2).
  int _seq = 0;
  // Giữ tham chiếu từ didChangeDependencies: tra AppScope trong dispose() là không an toàn.
  late final AppServices _services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = _services = AppScope.of(context);
    services.sync.addListener(_reload);
    services.store.changes.addListener(_reload);
    () async {
      _pageSize = PaginationFooter.sanitize(int.tryParse(await services.store.getValue(_pageSizeKey) ?? ''));
      await _reload();
    }();
  }

  @override
  void dispose() {
    _services.sync.removeListener(_reload);
    _services.store.changes.removeListener(_reload);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  SessionQuery get _query {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (DateTime? from, DateTime? to) = switch (_range) {
      _Range.all => (null, null),
      _Range.d7 => (today.subtract(const Duration(days: 6)), null),
      _Range.d30 => (DateTime(now.year, now.month - 1, now.day), null),
      _Range.y1 => (DateTime(now.year - 1, now.month, now.day), null),
      // Khoảng tuỳ chọn tính trọn ngày cuối: [đầu ngày bắt đầu, đầu ngày SAU ngày kết thúc).
      _Range.custom => (_custom?.start, _custom == null ? null : DateUtils.addDaysToDate(_custom!.end, 1)),
    };
    return SessionQuery(text: _search.text, from: from, to: to);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _reload();
    });
    setState(() {}); // hiện/ẩn nút xoá
  }

  Future<void> _pickRange(_Range r) async {
    if (r == _Range.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year, now.month, now.day),
        initialDateRange: _custom,
      );
      if (picked == null) return;
      _custom = picked;
    }
    _range = r;
    _page = 1;
    await _reload();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final store = AppScope.of(context).store;
    final seq = ++_seq;
    final query = _query;
    setState(() => _loading = true);
    try {
      final total = await store.countSessions(query: query);
      final pages = total == 0 ? 1 : (total + _pageSize - 1) ~/ _pageSize;
      if (_page > pages) _page = pages;
      final rows = await store.listSessions(limit: _pageSize, offset: (_page - 1) * _pageSize, query: query);
      if (!mounted || seq != _seq) return;
      setState(() {
        _total = total;
        _rows = rows;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      // QA-01: lỗi kho (vd. SQLite thiếu hàm) không được để màn trống im lặng.
      debugPrint('history_load_failed ${e.runtimeType}');
      if (!mounted || seq != _seq) return;
      setState(() {
        _rows = const [];
        _loading = false;
        _failed = true;
      });
    }
  }

  String _emptyText(BuildContext context) {
    final l = context.l10n;
    if (_failed) return l.historyLoadFailed;
    final q = _query;
    if (q.terms.isNotEmpty) return l.historyNoMatchQuery(_search.text.trim());
    if (q.isActive) return l.historyNoMatch;
    return l.historyEmpty;
  }

  Widget _filterBar(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    String label(_Range r) => switch (r) {
      _Range.all => l.historyRangeAll,
      _Range.d7 => l.historyRange7d,
      _Range.d30 => l.historyRange30d,
      _Range.y1 => l.historyRange1y,
      _Range.custom => _custom == null || _range != _Range.custom ? l.historyRangeCustom : _rangeLabel(_custom!),
    };
    final active = _query.isActive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SdbSpacing.s3, SdbSpacing.s3, SdbSpacing.s3, SdbSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l.historySearchHint,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.historyClearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        _onSearchChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: SdbSpacing.s2),
          Semantics(
            label: l.historyRangeLabel,
            container: true,
            child: Wrap(
              spacing: SdbSpacing.s2,
              runSpacing: SdbSpacing.s1,
              children: [
                for (final r in _Range.values)
                  ChoiceChip(label: Text(label(r)), selected: _range == r, onSelected: (_) => _pickRange(r)),
              ],
            ),
          ),
          if (active && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: SdbSpacing.s2),
              child: Semantics(
                liveRegion: true,
                child: Text(l.historyResultCount(_total), style: TextStyle(color: p.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppServices services, MeasurementSession s) {
    final p = context.palette;
    return ListTile(
      title: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatDateTime(s.startedAt)} · ${formatDuration(s.durationSeconds)}'
        '${s.dirty && services.auth.signedIn ? context.l10n.notSynced : ''}',
        style: TextStyle(color: p.textMuted),
      ),
      trailing: Text(
        '${formatNumber(s.summary['laeq'] ?? double.nan)} dBA',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SessionDetailPage(sessionId: s.id)));
        await _reload();
      },
    );
  }

  /// Cùng năm hiện tại ⇒ bỏ năm cho chip ngắn (QA-08: chữ cỡ lớn cắt mất ngày kết thúc).
  static String _rangeLabel(DateTimeRange r) {
    final now = DateTime.now().year;
    if (r.start.year != now || r.end.year != now) return '${formatDate(r.start)} – ${formatDate(r.end)}';
    return '${formatDayMonth(r.start)} – ${formatDayMonth(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
        actions: [IconButton(tooltip: context.l10n.reload, onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(SdbSpacing.s4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // QA-08: thanh tìm/lọc cuộn CÙNG danh sách. Cố định phía trên thì chữ cỡ lớn + bàn phím mở làm danh sách
              // còn 0 px và kết quả không bao giờ hiện.
              Expanded(
                child: AnimatedOpacity(
                  opacity: _loading ? 0.5 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _filterBar(context)),
                      SliverToBoxAdapter(child: Divider(height: 1, color: p.border)),
                      if (_rows.isEmpty && !_loading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(SdbSpacing.s6),
                              child: Text(
                                _emptyText(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.textMuted),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList.separated(
                          itemCount: _rows.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: p.border),
                          itemBuilder: (context, i) => _row(context, services, _rows[i]),
                        ),
                    ],
                  ),
                ),
              ),
              PaginationFooter(
                pageSize: _pageSize,
                page: _page,
                total: _total,
                loading: _loading,
                onPage: (page) {
                  _page = page;
                  _reload();
                },
                onPageSize: (size) {
                  _page = PaginationFooter.pageAfterResize(_page, _pageSize, size);
                  _pageSize = size;
                  services.store.setValue(_pageSizeKey, '$size');
                  _reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Range { all, d7, d30, y1, custom }
