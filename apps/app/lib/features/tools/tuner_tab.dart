import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';

/// Đo tần số cơ bản (cao độ) + nốt nhạc + lệch cent, kèm tần số trội của phổ.
class TunerTab extends StatelessWidget {
  const TunerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final m = services.measurement;
    return ListenableBuilder(
      listenable: Listenable.merge([m, services.settings]),
      builder: (context, _) {
        final p = context.palette;
        final pitch = m.pitch;
        final reliable = pitch != null && pitch.clarity >= 0.8;
        final note = reliable ? noteInfo(pitch.frequencyHz, services.settings.a4Hz) : null;
        final cents = note?.cents ?? 0;
        final inTune = note != null && cents.abs() <= 5;
        return ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
          Center(
            child: Semantics(
              liveRegion: true,
              label: note == null ? context.l10n.pitchNotDetected : context.l10n.noteSemantics(note.name, formatNumber(cents)),
              child: Column(children: [
                Text(note?.name ?? '-',
                    style: TextStyle(fontSize: 96, fontWeight: FontWeight.w600, color: inTune ? p.chartLevelSafe : p.textPrimary)),
                Text(reliable ? formatHz(pitch.frequencyHz) : context.l10n.noPitchedSound,
                    style: TextStyle(fontSize: 22, color: p.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          ),
          const SizedBox(height: SdbSpacing.s4),
          _CentsMeter(cents: note == null ? null : cents),
          const SizedBox(height: SdbSpacing.s4),
          StatGrid(children: [
            StatTile(label: context.l10n.deviation, value: note == null ? '-' : '${cents >= 0 ? '+' : ''}${formatNumber(cents)} cent'),
            StatTile(label: context.l10n.clarity, value: pitch == null ? '-' : formatPercent(pitch.clarity * 100, digits: 0)),
            StatTile(label: 'MIDI', value: note == null ? '-' : '${note.midi}'),
            StatTile(label: context.l10n.dominantFft, value: formatHz(m.peak?.frequencyHz ?? double.nan)),
            StatTile(label: context.l10n.dominantLevel, value: formatDb(m.peak?.levelDb ?? double.nan)),
            StatTile(label: context.l10n.a4Standard, value: formatHz(services.settings.a4Hz)),
          ]),
          const SizedBox(height: SdbSpacing.s3),
          Text(
            context.l10n.pitchNote,
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
        ]);
      },
    );
  }
}

class _CentsMeter extends StatelessWidget {
  const _CentsMeter({required this.cents});
  final double? cents;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 40,
      child: LayoutBuilder(builder: (context, c) {
        final x = cents == null ? null : c.maxWidth / 2 + (cents!.clamp(-50, 50) / 50) * (c.maxWidth / 2 - 4);
        return Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(SdbRadius.lg)),
            ),
          ),
          Positioned(left: c.maxWidth / 2 - 1, top: 4, bottom: 4, child: Container(width: 2, color: p.chartLevelSafe)),
          if (x != null)
            Positioned(
              left: x - 3,
              top: 0,
              bottom: 0,
              child: Container(width: 6, decoration: BoxDecoration(color: p.chartLine, borderRadius: BorderRadius.circular(3))),
            ),
          Positioned(left: 8, top: 10, child: Text('-50', style: TextStyle(color: p.textMuted, fontSize: 11))),
          Positioned(right: 8, top: 10, child: Text('+50', style: TextStyle(color: p.textMuted, fontSize: 11))),
        ]);
      }),
    );
  }
}
