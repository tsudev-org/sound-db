import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/pagination_footer.dart';
import 'session_detail_page.dart';

/// Danh sách phiên đo đã lưu, phân trang từ kho (không tải hết rồi cắt).
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
  List<MeasurementSession> _rows = const [];
  bool _initialised = false;
  // Giữ tham chiếu từ didChangeDependencies: tra AppScope trong dispose() là không an toàn.
  late final AppServices _services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = _services = AppScope.of(context);
    services.sync.addListener(_reload);
    () async {
      _pageSize = PaginationFooter.sanitize(int.tryParse(await services.store.getValue(_pageSizeKey) ?? ''));
      await _reload();
    }();
  }

  @override
  void dispose() {
    _services.sync.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final store = AppScope.of(context).store;
    setState(() => _loading = true);
    final total = await store.countSessions();
    final pages = total == 0 ? 1 : (total + _pageSize - 1) ~/ _pageSize;
    if (_page > pages) _page = pages;
    final rows = await store.listSessions(limit: _pageSize, offset: (_page - 1) * _pageSize);
    if (!mounted) return;
    setState(() {
      _total = total;
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
        actions: [
          IconButton(tooltip: context.l10n.reload, onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(SdbSpacing.s4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Expanded(
              child: _rows.isEmpty && !_loading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(SdbSpacing.s6),
                        child: Text(
                          context.l10n.historyEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted),
                        ),
                      ),
                    )
                  : AnimatedOpacity(
                      opacity: _loading ? 0.5 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: p.border),
                        itemBuilder: (context, i) {
                          final s = _rows[i];
                          return ListTile(
                            title: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${formatDateTime(s.startedAt)} · ${formatDuration(s.durationSeconds)}'
                              '${s.dirty && services.auth.signedIn ? context.l10n.notSynced : ''}',
                              style: TextStyle(color: p.textMuted),
                            ),
                            trailing: Text('${formatNumber(s.summary['laeq'] ?? double.nan)} dBA',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SessionDetailPage(sessionId: s.id)));
                              await _reload();
                            },
                          );
                        },
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
          ]),
        ),
      ),
    );
  }
}
