import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../services/measurement.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Nút Bắt đầu/Tạm dừng dùng ở thanh tiêu đề mọi màn hình đo.
class RunButton extends StatelessWidget {
  const RunButton({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context).measurement;
    return VisibleListenableBuilder(
      listenable: m,
      select: () => m.state,
      builder: (context, _) {
        final running = m.state == MeterState.running;
        final starting = m.state == MeterState.starting;
        return Padding(
          padding: const EdgeInsets.only(right: SdbSpacing.s2),
          child: FilledButton.icon(
            onPressed: starting ? null : (running ? m.pause : m.start),
            icon: Icon(running ? Icons.pause : Icons.mic),
            label: Text(running ? context.l10n.pause : (m.state == MeterState.paused ? context.l10n.resume : context.l10n.startMeasuring)),
          ),
        );
      },
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Tooltip(
        message: hint ?? '',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SdbSpacing.s3, vertical: SdbSpacing.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lưới thẻ số liệu co giãn theo bề ngang.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth > 900 ? 6 : (c.maxWidth > 560 ? 4 : 3);
      final width = (c.maxWidth - (columns - 1) * SdbSpacing.s2) / columns;
      return Wrap(
        spacing: SdbSpacing.s2,
        runSpacing: SdbSpacing.s2,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    });
  }
}

/// Thông báo trạng thái (cảnh báo hiệu chuẩn, lỗi micro).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.message, this.danger = false, this.action});

  final String message;
  final bool danger;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.danger : p.warning;
    return Container(
      padding: const EdgeInsets.all(SdbSpacing.s3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SdbRadius.lg),
        border: Border.all(color: color),
        color: p.bgSurface,
      ),
      child: Row(children: [
        Icon(danger ? Icons.error_outline : Icons.info_outline, color: color, semanticLabel: danger ? context.l10n.error : context.l10n.notice),
        const SizedBox(width: SdbSpacing.s3),
        Expanded(child: Text(message, style: TextStyle(color: p.textPrimary))),
        ?action,
      ]),
    );
  }
}

/// Thông báo chung ở cuối màn hình.
void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

/// Dấu hiệu TsuDEV đặt trước mọi liên kết tới tsudev.com (tsudev-standards v5.1.0 BRAND_ASSETS 4.1.0): >= 16 px,
/// nhãn trợ năng "TsuDEV". Ảnh sinh bởi apps/web/scripts/brand-assets.mjs (cùng nguồn chân trang web).
class TsuDevMark extends StatelessWidget {
  const TsuDevMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/tsudev-mark.png',
    width: size,
    height: size,
    semanticLabel: 'TsuDEV',
    filterQuality: FilterQuality.medium,
  );
}

/// Như [ListenableBuilder] nhưng KHÔNG dựng lại khi trang chứa nó đang ẩn (TickerMode tắt - vỏ app tắt cho trang ẩn của
/// IndexedStack); có thông báo lỡ khi ẩn thì dựng lại MỘT lần lúc hiện lại. Dùng cho mọi widget nghe
/// MeasurementController (báo 20 lần/giây): trang ẩn dựng lại theo nhịp đo làm app vẽ 20 khung/giây ở mọi tab (QA-11).
///
/// [select] (tuỳ chọn): chỉ dựng lại khi giá trị nó trả về đổi (so bằng `==` - dùng chuỗi đã định dạng hoặc record,
/// KHÔNG dùng double NaN). Mỗi phần của trang chọn đúng số nó hiển thị ⇒ nhịp đo không dựng lại cả trang (QA-11 bước 3).
class VisibleListenableBuilder extends StatefulWidget {
  const VisibleListenableBuilder({super.key, required this.listenable, required this.builder, this.child, this.select});

  final Listenable listenable;
  final TransitionBuilder builder;
  final Widget? child;
  final Object? Function()? select;

  @override
  State<VisibleListenableBuilder> createState() => _VisibleListenableBuilderState();
}

class _VisibleListenableBuilderState extends State<VisibleListenableBuilder> {
  ValueListenable<TickerModeData>? _mode;
  bool _visible = true;
  bool _missed = false;
  Object? _selected;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(VisibleListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = TickerMode.getValuesNotifier(context);
    if (!identical(mode, _mode)) {
      _mode?.removeListener(_modeChanged);
      _mode = mode..addListener(_modeChanged);
    }
    _visible = mode.value.enabled;
  }

  void _changed() {
    final select = widget.select;
    if (select != null) {
      final value = select();
      if (value == _selected) return;
      _selected = value;
    }
    if (_visible) {
      setState(() {});
    } else {
      _missed = true;
    }
  }

  void _modeChanged() {
    final visible = _mode!.value.enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (visible && _missed) {
      _missed = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    _mode?.removeListener(_modeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.select?.call();
    return widget.builder(context, widget.child);
  }
}

/// Báo [onDemand] `true` khi trang chứa nó bắt đầu HIỂN THỊ, `false` khi ẩn hoặc bị gỡ (theo TickerMode như
/// [VisibleListenableBuilder]). Dùng để xin phần tính toán chỉ trang đó cần (dò cao độ, phổ) - QA-11.
/// [owner] là đối tượng nhận nhu cầu: đổi owner ⇒ nhả nhu cầu ở owner cũ rồi xin ở owner mới.
class DemandWhileVisible extends StatefulWidget {
  const DemandWhileVisible({super.key, required this.owner, required this.onDemand, required this.child});

  final Object owner;
  final ValueChanged<bool> onDemand;
  final Widget child;

  @override
  State<DemandWhileVisible> createState() => _DemandWhileVisibleState();
}

class _DemandWhileVisibleState extends State<DemandWhileVisible> {
  ValueListenable<TickerModeData>? _mode;
  bool _demanding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = TickerMode.getValuesNotifier(context);
    if (!identical(mode, _mode)) {
      _mode?.removeListener(_sync);
      _mode = mode..addListener(_sync);
    }
    _sync();
  }

  @override
  void didUpdateWidget(DemandWhileVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.owner, widget.owner) && _demanding) {
      oldWidget.onDemand(false);
      _demanding = false;
      _sync();
    }
  }

  void _sync() => _set(_mode?.value.enabled ?? false);

  void _set(bool wanted) {
    if (wanted == _demanding) return;
    _demanding = wanted;
    widget.onDemand(wanted);
  }

  @override
  void dispose() {
    _mode?.removeListener(_sync);
    _set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
