import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../services/measurement.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/level_dial.dart';
import '../../services/audio_input.dart';
import '../../services/system_settings.dart';
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
        title: Text(context.l10n.meterTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.meterReferenceTooltip,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const _ReferenceSheet()),
          ),
          const RunButton(),
        ],
      ),
      body: VisibleListenableBuilder(
        listenable: Listenable.merge([m, settings]),
        // Khung trang chỉ dựng lại khi lỗi, hiệu chuẩn, trọng số hoặc "đã có số đo" đổi; số đo 20 lần/giây nằm ở các
        // phần con, mỗi phần chỉ dựng khi chuỗi nó hiển thị đổi (QA-11 bước 3: dựng cả ListView mỗi nhịp = 32 % CPU Dart).
        select: () =>
            (m.error, m.errorCode, m.snapshot == null, settings.weighting, settings.timeWeighting, settings.calibrated),
        builder: (context, _) {
          final hasData = m.snapshot != null;
          final w = settings.weighting, t = settings.timeWeighting;
          return ListView(
            padding: const EdgeInsets.all(SdbSpacing.s4),
            children: [
              if (m.error != null) ...[
                NoticeBanner(
                  message: m.error!,
                  danger: true,
                  action: m.errorCode == AudioInputException.permissionDenied && SystemSettings.supported
                      ? TextButton(onPressed: SystemSettings.openAppSettings, child: Text(context.l10n.openSettings))
                      : null,
                ),
                const SizedBox(height: SdbSpacing.s3),
              ],
              if (!settings.calibrated) ...[
                NoticeBanner(message: context.l10n.meterNotCalibrated),
                const SizedBox(height: SdbSpacing.s3),
              ],
              VisibleListenableBuilder(
                listenable: m,
                select: () => formatNumber(m.snapshot?.level(w, t) ?? double.nan),
                builder: (context, _) {
                  final p = context.palette;
                  final s = m.snapshot;
                  final level = s?.level(w, t) ?? double.nan;
                  final zone = level >= SdbMeterZones.danger
                      ? p.chartLevelDanger
                      : level >= SdbMeterZones.caution
                      ? p.chartLevelCaution
                      : p.chartLevelSafe;
                  // Vùng live CHỈ mang tên vùng mức (nút chứa bọc ngoài): số đo đổi 20 lần/giây, nếu là vùng live thì
                  // TalkBack đọc dồn liên tục (QA-05). Số hiện tại ở nút con - chạm mặt đồng hồ để nghe.
                  return Semantics(
                    container: true,
                    liveRegion: s != null,
                    label: s == null
                        ? null
                        : level >= SdbMeterZones.danger
                        ? context.l10n.meterZoneDanger
                        : level >= SdbMeterZones.caution
                        ? context.l10n.meterZoneCaution
                        : context.l10n.meterZoneSafe,
                    child: Center(
                      child: Semantics(
                        container: true,
                        label: context.l10n.meterLevelSemantics('L${w.label}${t.label}', formatNumber(level)),
                        child: LevelDial(
                          level: s == null ? double.nan : level,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('L${w.label}${t.label}', style: TextStyle(color: p.textMuted, fontSize: 16)),
                              Text(
                                formatNumber(level),
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w600,
                                  color: s == null ? p.textMuted : zone,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  height: 1.05,
                                ),
                              ),
                              Text('dB(${w.label})', style: TextStyle(color: p.textSecondary, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                    segments: [
                      ButtonSegment(
                        value: TimeWeighting.fast,
                        label: Text(context.l10n.timeFast),
                        tooltip: 'F - 125 ms',
                      ),
                      ButtonSegment(value: TimeWeighting.slow, label: Text(context.l10n.timeSlow), tooltip: 'S - 1 s'),
                      ButtonSegment(
                        value: TimeWeighting.impulse,
                        label: Text(context.l10n.timeImpulse),
                        tooltip: 'I - 35 ms / ${formatNumber(1.5)} s',
                      ),
                    ],
                    selected: {t},
                    onSelectionChanged: (v) => settings.setTimeWeighting(v.first),
                  ),
                ],
              ),
              const SizedBox(height: SdbSpacing.s4),
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Lưới + nhãn dB tĩnh: lớp riêng, không vẽ lại theo nhịp (6,6 % CPU Dart khi vẽ cùng đường mức).
                    RepaintBoundary(child: CustomPaint(painter: DbGridPainter(palette: context.palette))),
                    VisibleListenableBuilder(
                      listenable: m,
                      select: () => m.displayVersion,
                      builder: (context, _) => RepaintBoundary(
                        child: CustomPaint(
                          painter: LevelHistoryPainter(
                            m.levelHistory,
                            context.palette,
                            capacity: MeasurementController.historyLength,
                            version: m.historyVersion,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(context.l10n.meterLast2Min, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
              const SizedBox(height: SdbSpacing.s4),
              VisibleListenableBuilder(
                listenable: m,
                select: () => _statKey(m.snapshot, w, t),
                builder: (context, _) {
                  final s = m.snapshot;
                  return StatGrid(
                    children: [
                      StatTile(
                        label: 'L${w.label}eq',
                        value: formatNumber(s?.leq[w.index] ?? double.nan),
                        hint: context.l10n.meterLeqHint,
                      ),
                      StatTile(
                        label: 'L${w.label}${t.label}max',
                        value: formatNumber(s?.max[w.index][t.index] ?? double.nan),
                      ),
                      StatTile(
                        label: 'L${w.label}${t.label}min',
                        value: formatNumber(s?.min[w.index][t.index] ?? double.nan),
                      ),
                      StatTile(
                        label: 'L${w.label}peak',
                        value: formatNumber(s?.peak[w.index] ?? double.nan),
                        hint: context.l10n.meterPeakHint,
                      ),
                      StatTile(
                        label: 'LAF10',
                        value: formatNumber(s?.percentiles[2] ?? double.nan),
                        hint: context.l10n.meterL10Hint,
                      ),
                      StatTile(label: 'LAF50', value: formatNumber(s?.percentiles[3] ?? double.nan)),
                      StatTile(
                        label: 'LAF90',
                        value: formatNumber(s?.percentiles[4] ?? double.nan),
                        hint: context.l10n.meterL90Hint,
                      ),
                      StatTile(label: 'LAE (SEL)', value: formatNumber(s?.selA ?? double.nan)),
                      StatTile(label: context.l10n.duration, value: formatDuration(s?.elapsedSeconds ?? 0)),
                    ],
                  );
                },
              ),
              const SizedBox(height: SdbSpacing.s4),
              VisibleListenableBuilder(
                listenable: m,
                select: () => _DoseCard.shownValues(m.snapshot),
                builder: (context, _) => _DoseCard(snapshot: m.snapshot),
              ),
              const SizedBox(height: SdbSpacing.s4),
              Wrap(
                spacing: SdbSpacing.s2,
                runSpacing: SdbSpacing.s2,
                children: [
                  OutlinedButton.icon(
                    onPressed: hasData ? m.resetSession : null,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(context.l10n.resetSession),
                  ),
                  FilledButton.icon(
                    onPressed: hasData ? () => saveCurrentSession(context) : null,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(context.l10n.saveSession),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chuỗi các số thẻ thống kê đang hiển thị - thẻ chỉ dựng lại khi chuỗi này đổi.
String _statKey(LevelSnapshot? s, Weighting w, TimeWeighting t) => s == null
    ? ''
    : '${[s.leq[w.index], s.max[w.index][t.index], s.min[w.index][t.index], s.peak[w.index], s.percentiles[2], s.percentiles[3], s.percentiles[4], s.selA].map(formatNumber).join('|')}'
          '|${formatDuration(s.elapsedSeconds)}';

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.snapshot});
  final LevelSnapshot? snapshot;

  /// Chuỗi đang hiển thị (liều, TWA) - thẻ chỉ dựng lại khi chuỗi này đổi.
  static String shownValues(LevelSnapshot? s) => s == null
      ? ''
      : '${formatPercent(s.doseNioshPercent, digits: 2)}|${formatNumber(s.twaNiosh)}|'
            '${formatPercent(s.doseOshaPercent, digits: 2)}|${formatNumber(s.twaOsha)}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = snapshot;
    Widget row(String name, double dose, double twa, String rule) {
      final color = dose >= 100 ? p.chartLevelDanger : (dose >= 50 ? p.chartLevelCaution : p.chartLevelSafe);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SdbSpacing.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: SdbSpacing.s2),
                Expanded(
                  child: Text(rule, style: TextStyle(color: p.textMuted, fontSize: 12)),
                ),
                Text('${formatPercent(dose, digits: 2)} · TWA ${formatNumber(twa)}'),
              ],
            ),
            const SizedBox(height: SdbSpacing.s1),
            LinearProgressIndicator(
              value: (dose / 100).clamp(0, 1),
              color: color,
              backgroundColor: p.bgSubtle,
              minHeight: 6,
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SdbSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.doseTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: SdbSpacing.s2),
            row('NIOSH', s?.doseNioshPercent ?? 0, s?.twaNiosh ?? double.nan, context.l10n.doseNioshRule),
            row('OSHA', s?.doseOshaPercent ?? 0, s?.twaOsha ?? double.nan, context.l10n.doseOshaRule),
            const SizedBox(height: SdbSpacing.s1),
            Text(context.l10n.doseNote, style: TextStyle(color: p.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ReferenceSheet extends StatelessWidget {
  const _ReferenceSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final rows = [
      ('0', l.ref0),
      ('20-30', l.ref20),
      ('40-50', l.ref40),
      ('60', l.ref60),
      ('70', l.ref70),
      ('85', l.ref85),
      ('95-100', l.ref95),
      ('110', l.ref110),
      ('120-130', l.ref120),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(SdbSpacing.s4),
        children: [
          Text(l.refTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: SdbSpacing.s2),
          for (final (db, text) in rows)
            ListTile(
              dense: true,
              leading: SizedBox(
                width: 64,
                child: Text(db, style: TextStyle(color: p.textLink)),
              ),
              title: Text(text),
            ),
        ],
      ),
    );
  }
}
