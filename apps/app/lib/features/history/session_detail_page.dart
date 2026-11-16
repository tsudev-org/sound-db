import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
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
    if (mounted) showMessage(context, 'Đã lưu $name');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phiên đo?'),
        content: const Text('Phiên sẽ bị xóa trên máy này và trên mọi thiết bị đã đồng bộ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
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
        title: Text(s?.label ?? 'Phiên đo'),
        actions: [
          if (s != null)
            PopupMenuButton<String>(
              tooltip: 'Thao tác',
              onSelected: (v) => v == 'delete' ? _delete() : _export(v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'csv', child: Text('Xuất CSV')),
                PopupMenuItem(value: 'json', child: Text('Xuất JSON')),
                PopupMenuItem(value: 'delete', child: Text('Xóa phiên')),
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
                StatTile(label: 'Liều NIOSH', value: formatPercent(s.summary['dose_niosh'] ?? double.nan, digits: 2)),
                StatTile(label: 'Liều OSHA', value: formatPercent(s.summary['dose_osha'] ?? double.nan, digits: 2)),
              ]),
              const SizedBox(height: SdbSpacing.s4),
              const Text('LAeq theo thời gian', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: SdbSpacing.s2),
              SizedBox(
                height: 180,
                child: CustomPaint(painter: LevelHistoryPainter(s.seriesLaeq, p, capacity: s.seriesLaeq.length.clamp(2, 1 << 30))),
              ),
              if (s.thirdOctaveLzeq.isNotEmpty) ...[
                const SizedBox(height: SdbSpacing.s4),
                const Text('Phổ 1/3 octave trung bình (LZeq)', style: TextStyle(fontWeight: FontWeight.w600)),
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
              Text('Offset hiệu chuẩn khi đo: ${formatDb(s.calibrationOffsetDb)}', style: TextStyle(color: p.textMuted, fontSize: 12)),
            ]),
    );
  }
}
