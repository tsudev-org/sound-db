import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  MeasurementSession? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).store.getSession(widget.sessionId).then((s) {
      if (mounted) setState(() => _session = s);
    });
  }

  Future<void> _export(String format) async {
    final s = _session!;
    final content = format == 'csv' ? s.toCsv() : const JsonEncoder.withIndent('  ').convert(s.toData());
    final name = 'sound-db-${s.startedAt.toIso8601String().substring(0, 19).replaceAll(':', '-')}.$format';
    final bytes = Uint8List.fromList(utf8.encode(format == 'csv' ? '﻿$content' : content));
    final mime = format == 'csv' ? 'text/csv' : 'application/json';
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: mime)], fileNameOverrides: [name]));
      return;
    }
    final location = await getSaveLocation(suggestedName: name);
    if (location == null) return;
    await XFile.fromData(bytes, name: name, mimeType: mime).saveTo(location.path);
    if (mounted) showMessage(context, context.l10n.savedFile(name));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteSessionTitle),
        content: Text(context.l10n.deleteSessionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final services = AppScope.of(context);
    final s = _session!
      ..deleted = true
      ..dirty = true
      ..updatedAt = DateTime.now().toUtc();
    await services.store.saveSession(s);
    if (mounted) Navigator.pop(context);
    await services.sync.syncNow(onlyIfAuto: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.label ?? context.l10n.sessionFallback),
        actions: [
          if (s != null)
            PopupMenuButton<String>(
              tooltip: context.l10n.actions,
              onSelected: (v) => v == 'delete' ? _delete() : _export(v),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'csv', child: Text(context.l10n.exportCsv)),
                PopupMenuItem(value: 'json', child: Text(context.l10n.exportJson)),
                PopupMenuItem(value: 'delete', child: Text(context.l10n.deleteSession)),
              ],
            ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
              Text('${formatDateTime(s.startedAt)} · ${formatDuration(s.durationSeconds)} · ${s.deviceModel}',
                  style: TextStyle(color: p.textMuted)),
              const SizedBox(height: SdbSpacing.s3),
              StatGrid(children: [
                for (final (key, label) in const [
                  ('laeq', 'LAeq'), ('lceq', 'LCeq'), ('lzeq', 'LZeq'), ('lafmax', 'LAFmax'), ('lafmin', 'LAFmin'),
                  ('lcpeak', 'LCpeak'), ('l10', 'LAF10'), ('l50', 'LAF50'), ('l90', 'LAF90'), ('sel_a', 'LAE'),
                ])
                  StatTile(label: label, value: formatNumber(s.summary[key] ?? double.nan)),
                StatTile(label: context.l10n.doseNiosh, value: formatPercent(s.summary['dose_niosh'] ?? double.nan, digits: 2)),
                StatTile(label: context.l10n.doseOsha, value: formatPercent(s.summary['dose_osha'] ?? double.nan, digits: 2)),
              ]),
              const SizedBox(height: SdbSpacing.s4),
              Text(context.l10n.laeqOverTime, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: SdbSpacing.s2),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: DbGridPainter(palette: p),
                  foregroundPainter:
                      LevelHistoryPainter(s.seriesLaeq, p, capacity: s.seriesLaeq.length.clamp(2, 1 << 30), version: 0),
                ),
              ),
              if (s.thirdOctaveLzeq.isNotEmpty) ...[
                const SizedBox(height: SdbSpacing.s4),
                Text(context.l10n.thirdOctaveAvg, style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: SdbSpacing.s2),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: BandsPainter(
                      levels: s.thirdOctaveLzeq.values.toList(),
                      labels: [
                        for (final k in s.thirdOctaveLzeq.keys)
                          (double.tryParse(k) ?? 0) >= 1000 ? '${(double.parse(k) / 1000).toStringAsFixed(1)}k' : '${double.tryParse(k)?.round()}',
                      ],
                      minDb: 0,
                      maxDb: 120,
                      palette: p,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: SdbSpacing.s3),
              Text(context.l10n.calOffsetAtMeasure(formatDb(s.calibrationOffsetDb)), style: TextStyle(color: p.textMuted, fontSize: 12)),
            ]),
    );
  }
}
