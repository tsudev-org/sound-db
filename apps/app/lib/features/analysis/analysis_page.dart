import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/charts.dart';
import '../../services/settings.dart';
import '../../widgets/common.dart';

/// Phân tích tần số: phổ FFT, phổ đồ, dải octave.
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.analysisTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.spectrumSettings,
              icon: const Icon(Icons.tune),
              onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const _SpectrumSettings()),
            ),
            const RunButton(),
          ],
          bottom: TabBar(tabs: [Tab(text: context.l10n.tabFft), Tab(text: context.l10n.tabSpectrogram), Tab(text: context.l10n.tabOctave)]),
        ),
        body: const TabBarView(children: [_SpectrumTab(), _SpectrogramTab(), _OctaveTab()]),
      ),
    );
  }
}

class _SpectrumTab extends StatefulWidget {
  const _SpectrumTab();

  @override
  State<_SpectrumTab> createState() => _SpectrumTabState();
}

class _SpectrumTabState extends State<_SpectrumTab> {
  double? _cursorHz;
  bool _showPeakHold = true;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final m = services.measurement;
    final settings = services.settings;
    return VisibleListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final p = context.palette;
        final spectrum = m.engine.spectrum;
        final axis = LogAxis(20, math.min(20000, m.sampleRate / 2));
        double? cursorDb;
        if (_cursorHz != null && m.spectrumDb.isNotEmpty) {
          final k = (_cursorHz! / spectrum.binHz).round().clamp(0, m.spectrumDb.length - 1);
          cursorDb = m.spectrumDb[k];
        }
        return Padding(
          padding: const EdgeInsets.all(SdbSpacing.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StatGrid(children: [
              StatTile(label: context.l10n.dominantFrequency, value: formatHz(m.peak?.frequencyHz ?? double.nan)),
              StatTile(label: context.l10n.peakLevel, value: formatDb(m.peak?.levelDb ?? double.nan)),
              StatTile(
                label: context.l10n.cursor,
                value: _cursorHz == null ? context.l10n.tapChart : '${formatHz(_cursorHz!)} · ${formatNumber(cursorDb ?? double.nan)}',
              ),
            ]),
            const SizedBox(height: SdbSpacing.s3),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                void setCursor(Offset local) {
                  const left = 26.0;
                  setState(() => _cursorHz = axis.toHz(local.dx - left, c.maxWidth - left));
                }

                return GestureDetector(
                  onTapDown: (d) => setCursor(d.localPosition),
                  onHorizontalDragUpdate: (d) => setCursor(d.localPosition),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(c.maxWidth, c.maxHeight),
                      painter: SpectrumPainter(
                        spectrum: m.spectrumDb,
                        peakHold: _showPeakHold ? m.peakHoldDb : m.spectrumDb.sublist(0, 0),
                        binHz: spectrum.binHz,
                        axis: axis,
                        minDb: settings.spectrumMinDb,
                        maxDb: settings.spectrumMaxDb,
                        palette: p,
                        peakHz: m.peak?.frequencyHz,
                        cursorHz: _cursorHz,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: SdbSpacing.s2),
            Wrap(spacing: SdbSpacing.s2, runSpacing: SdbSpacing.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              FilterChip(
                label: Text(context.l10n.peakHold),
                selected: _showPeakHold,
                onSelected: (v) => setState(() => _showPeakHold = v),
              ),
              OutlinedButton(onPressed: m.clearPeakHold, child: Text(context.l10n.clearPeak)),
              Text(
                context.l10n.fftInfo('${spectrum.size}', windowLabel(context.l10n, spectrum.windowKind), formatNumber(spectrum.binHz, digits: 2), settings.weighting.label),
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

class _SpectrogramTab extends StatelessWidget {
  const _SpectrogramTab();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final m = services.measurement;
    return VisibleListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final p = context.palette;
        final nyquist = math.min(20000.0, m.sampleRate / 2);
        return Padding(
          padding: const EdgeInsets.all(SdbSpacing.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.l10n.spectrogramNote(formatHz(nyquist)),
                style: TextStyle(color: p.textMuted, fontSize: 12)),
            const SizedBox(height: SdbSpacing.s2),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SdbRadius.lg),
                child: SpectrogramView(
                  rows: m.spectrogram,
                  minDb: services.settings.spectrumMinDb,
                  maxDb: services.settings.spectrumMaxDb,
                  version: m.engine.totalSamples,
                ),
              ),
            ),
            const SizedBox(height: SdbSpacing.s1),
            // Nhãn đặt ĐÚNG vị trí trên trục log (không dàn đều), chữ ngắn để vừa màn hình hẹp.
            SizedBox(
              height: 16,
              child: LayoutBuilder(builder: (context, c) {
                final axis = LogAxis(20, nyquist);
                return Stack(clipBehavior: Clip.none, children: [
                  for (final (hz, label) in const [(20.0, '20'), (100.0, '100'), (1000.0, '1k'), (10000.0, '10k')])
                    if (hz <= nyquist)
                      Positioned(
                        left: (axis.toX(hz, c.maxWidth) - 8).clamp(0, c.maxWidth - 24),
                        child: Text(label, style: TextStyle(color: p.chartAxis, fontSize: 11)),
                      ),
                  Positioned(right: 0, child: Text('Hz', style: TextStyle(color: p.chartAxis, fontSize: 11))),
                ]);
              }),
            ),
          ]),
        );
      },
    );
  }
}

class _OctaveTab extends StatefulWidget {
  const _OctaveTab();

  @override
  State<_OctaveTab> createState() => _OctaveTabState();
}

class _OctaveTabState extends State<_OctaveTab> {
  int _fraction = 3;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final m = services.measurement;
    return VisibleListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final p = context.palette;
        final bands = m.engine.bands(_fraction);
        final levels = _fraction == 3 ? m.thirdOctave : m.fullOctave;
        final double minBins = bands.isEmpty ? 0 : (bands.first.upperHz - bands.first.lowerHz) / m.engine.spectrum.binHz;
        return Padding(
          padding: const EdgeInsets.all(SdbSpacing.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 1, label: Text('1/1 octave')), ButtonSegment(value: 3, label: Text('1/3 octave'))],
              selected: {_fraction},
              onSelectionChanged: (v) => setState(() => _fraction = v.first),
            ),
            if (minBins < 3) ...[
              const SizedBox(height: SdbSpacing.s2),
              NoticeBanner(
                message: context.l10n.lowBandWarning(formatNumber(minBins)),
              ),
            ],
            const SizedBox(height: SdbSpacing.s3),
            Expanded(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: BandsPainter(
                    levels: levels,
                    labels: [for (final b in bands) b.label],
                    minDb: services.settings.spectrumMinDb,
                    maxDb: services.settings.spectrumMaxDb,
                    palette: p,
                  ),
                ),
              ),
            ),
            Text(context.l10n.bandNote(services.settings.weighting.label),
                style: TextStyle(color: p.textMuted, fontSize: 12)),
          ]),
        );
      },
    );
  }
}

class _SpectrumSettings extends StatelessWidget {
  const _SpectrumSettings();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(SdbSpacing.s4), children: [
          Text(context.l10n.spectrumSettings, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: SdbSpacing.s3),
          DropdownButtonFormField<int>(
            initialValue: settings.fftSize,
            decoration: InputDecoration(labelText: context.l10n.fftSize),
            items: [for (final n in Settings.fftSizes) DropdownMenuItem(value: n, child: Text(context.l10n.fftSamples('$n')))],
            onChanged: (v) => settings.setFft(v!, settings.window),
          ),
          const SizedBox(height: SdbSpacing.s3),
          DropdownButtonFormField<WindowKind>(
            initialValue: settings.window,
            decoration: InputDecoration(labelText: context.l10n.window),
            items: [for (final w in WindowKind.values) DropdownMenuItem(value: w, child: Text(windowLabel(context.l10n, w)))],
            onChanged: (v) => settings.setFft(settings.fftSize, v!),
          ),
          const SizedBox(height: SdbSpacing.s3),
          Text(context.l10n.displayRange(formatNumber(settings.spectrumMinDb, digits: 0), formatNumber(settings.spectrumMaxDb, digits: 0))),
          RangeSlider(
            min: -40,
            max: 160,
            divisions: 40,
            values: RangeValues(settings.spectrumMinDb, settings.spectrumMaxDb),
            onChanged: (v) {
              if (v.end - v.start >= 20) settings.setSpectrumRange(v.start, v.end);
            },
          ),
        ]),
      ),
    );
  }
}
