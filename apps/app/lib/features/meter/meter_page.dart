import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../services/measurement.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'save_session.dart';

/// Màn hình chính: máy đo mức âm (sound level meter).
class MeterPage extends StatelessWidget {
  const MeterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final m = services.measurement;
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đo mức âm'),
        actions: [
          IconButton(
            tooltip: 'Mức tham chiếu thường gặp',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const _ReferenceSheet()),
          ),
          const RunButton(),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([m, settings]),
        builder: (context, _) {
          final p = context.palette;
          final s = m.snapshot;
          final w = settings.weighting, t = settings.timeWeighting;
          final level = s?.level(w, t) ?? double.nan;
          final zone = level >= SdbMeterZones.danger
              ? p.chartLevelDanger
              : level >= SdbMeterZones.caution
                  ? p.chartLevelCaution
                  : p.chartLevelSafe;
          return ListView(
            padding: const EdgeInsets.all(SdbSpacing.s4),
            children: [
              if (m.error != null) ...[
                NoticeBanner(message: m.error!, danger: true),
                const SizedBox(height: SdbSpacing.s3),
              ],
              if (!settings.calibrated) ...[
                const NoticeBanner(
                  message: 'Chưa hiệu chuẩn: số đo là ước lượng theo micro điển hình (sai số có thể vài dB). '
                      'Vào Cài đặt > Hiệu chuẩn để đo chính xác.',
                ),
                const SizedBox(height: SdbSpacing.s3),
              ],
              Center(
                child: Semantics(
                  liveRegion: true,
                  label: 'Mức âm L${w.label}${t.label} ${formatNumber(level)} đề-xi-ben',
                  child: Column(children: [
                    Text('L${w.label}${t.label}', style: TextStyle(color: p.textMuted, fontSize: 16)),
                    Text(
                      formatNumber(level),
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w600,
                        color: s == null ? p.textMuted : zone,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1.05,
                      ),
                    ),
                    Text('dB(${w.label})', style: TextStyle(color: p.textSecondary, fontSize: 18)),
                  ]),
                ),
              ),
              const SizedBox(height: SdbSpacing.s4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: SdbSpacing.s3,
                runSpacing: SdbSpacing.s2,
                children: [
                  SegmentedButton<Weighting>(
                    segments: [for (final v in Weighting.values) ButtonSegment(value: v, label: Text(v.label))],
                    selected: {w},
                    onSelectionChanged: (v) => settings.setWeighting(v.first),
                  ),
                  SegmentedButton<TimeWeighting>(
                    segments: const [
                      ButtonSegment(value: TimeWeighting.fast, label: Text('Nhanh'), tooltip: 'F - 125 ms'),
                      ButtonSegment(value: TimeWeighting.slow, label: Text('Chậm'), tooltip: 'S - 1 s'),
                      ButtonSegment(value: TimeWeighting.impulse, label: Text('Xung'), tooltip: 'I - 35 ms / 1,5 s'),
                    ],
                    selected: {t},
                    onSelectionChanged: (v) => settings.setTimeWeighting(v.first),
                  ),
                ],
              ),
              const SizedBox(height: SdbSpacing.s4),
              SizedBox(
                height: 160,
                child: RepaintBoundary(
                  child: CustomPaint(painter: LevelHistoryPainter(m.levelHistory, p, capacity: MeasurementController.historyLength)),
                ),
              ),
              Text('2 phút gần nhất', style: TextStyle(color: p.textMuted, fontSize: 12)),
              const SizedBox(height: SdbSpacing.s4),
              StatGrid(children: [
                StatTile(label: 'L${w.label}eq', value: formatNumber(s?.leq[w.index] ?? double.nan), hint: 'Mức tương đương liên tục của cả phiên'),
                StatTile(label: 'L${w.label}${t.label}max', value: formatNumber(s?.max[w.index][t.index] ?? double.nan)),
                StatTile(label: 'L${w.label}${t.label}min', value: formatNumber(s?.min[w.index][t.index] ?? double.nan)),
                StatTile(label: 'L${w.label}peak', value: formatNumber(s?.peak[w.index] ?? double.nan), hint: 'Đỉnh tức thời'),
                StatTile(label: 'LAF10', value: formatNumber(s?.percentiles[2] ?? double.nan), hint: 'Mức bị vượt 10% thời gian'),
                StatTile(label: 'LAF50', value: formatNumber(s?.percentiles[3] ?? double.nan)),
                StatTile(label: 'LAF90', value: formatNumber(s?.percentiles[4] ?? double.nan), hint: 'Ồn nền'),
                StatTile(label: 'LAE (SEL)', value: formatNumber(s?.selA ?? double.nan)),
                StatTile(label: 'Thời lượng', value: formatDuration(s?.elapsedSeconds ?? 0)),
              ]),
              const SizedBox(height: SdbSpacing.s4),
              _DoseCard(snapshot: s),
              const SizedBox(height: SdbSpacing.s4),
              Wrap(spacing: SdbSpacing.s2, runSpacing: SdbSpacing.s2, children: [
                OutlinedButton.icon(
                  onPressed: s == null ? null : m.resetSession,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Đặt lại phiên'),
                ),
                FilledButton.icon(
                  onPressed: s == null ? null : () => saveCurrentSession(context),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu phiên đo'),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.snapshot});
  final LevelSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = snapshot;
    Widget row(String name, double dose, double twa, String rule) {
      final color = dose >= 100 ? p.chartLevelDanger : (dose >= 50 ? p.chartLevelCaution : p.chartLevelSafe);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SdbSpacing.s1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: SdbSpacing.s2),
            Expanded(child: Text(rule, style: TextStyle(color: p.textMuted, fontSize: 12))),
            Text('${formatPercent(dose, digits: 2)} · TWA ${formatNumber(twa)}'),
          ]),
          const SizedBox(height: SdbSpacing.s1),
          LinearProgressIndicator(value: (dose / 100).clamp(0, 1), color: color, backgroundColor: p.bgSubtle, minHeight: 6),
        ]),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SdbSpacing.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Liều tiếp xúc tiếng ồn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: SdbSpacing.s2),
          row('NIOSH', s?.doseNioshPercent ?? 0, s?.twaNiosh ?? double.nan, '85 dBA / 8 giờ, hệ số trao đổi 3 dB'),
          row('OSHA', s?.doseOshaPercent ?? 0, s?.twaOsha ?? double.nan, '90 dBA / 8 giờ, hệ số trao đổi 5 dB'),
          const SizedBox(height: SdbSpacing.s1),
          Text('Tính trên LAS từ khi bắt đầu phiên. 100% là giới hạn tiếp xúc cho một ngày làm việc.',
              style: TextStyle(color: p.textMuted, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ReferenceSheet extends StatelessWidget {
  const _ReferenceSheet();

  static const _rows = [
    ('0', 'Ngưỡng nghe'),
    ('20-30', 'Thì thầm, phòng ngủ yên tĩnh'),
    ('40-50', 'Thư viện, văn phòng yên tĩnh'),
    ('60', 'Trò chuyện bình thường'),
    ('70', 'Máy hút bụi, đường phố đông'),
    ('85', 'Giao thông dày đặc - ngưỡng tiếp xúc 8 giờ (NIOSH)'),
    ('95-100', 'Xe máy tăng ga, máy khoan'),
    ('110', 'Hòa nhạc, vũ trường'),
    ('120-130', 'Còi xe cứu thương sát tai - ngưỡng đau'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(SdbSpacing.s4),
        children: [
          const Text('Mức âm tham chiếu (dBA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: SdbSpacing.s2),
          for (final (db, text) in _rows)
            ListTile(dense: true, leading: SizedBox(width: 64, child: Text(db, style: TextStyle(color: p.textLink))), title: Text(text)),
        ],
      ),
    );
  }
}
