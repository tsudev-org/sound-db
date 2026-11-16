import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
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
          title: const Text('Phân tích tần số'),
          actions: [
            IconButton(
              tooltip: 'Thiết lập phổ',
              icon: const Icon(Icons.tune),
              onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const _SpectrumSettings()),
            ),
            const RunButton(),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Phổ FFT'), Tab(text: 'Phổ đồ'), Tab(text: 'Dải octave')]),
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
    return ListenableBuilder(
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
              StatTile(label: 'Tần số trội', value: formatHz(m.peak?.frequencyHz ?? double.nan)),
              StatTile(label: 'Mức đỉnh', value: formatDb(m.peak?.levelDb ?? double.nan)),
              StatTile(
                label: 'Con trỏ',
                value: _cursorHz == null ? 'Chạm biểu đồ' : '${formatHz(_cursorHz!)} · ${formatNumber(cursorDb ?? double.nan)}',
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
                label: const Text('Giữ đỉnh'),
                selected: _showPeakHold,
                onSelected: (v) => setState(() => _showPeakHold = v),
              ),
              OutlinedButton(onPressed: m.clearPeakHold, child: const Text('Xóa đỉnh')),
              Text(
                'FFT ${spectrum.size} · ${spectrum.windowKind.label} · ${formatNumber(spectrum.binHz, digits: 2)} Hz/bin · trọng số ${settings.weighting.label}',
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
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final p = context.palette;
        final nyquist = math.min(20000.0, m.sampleRate / 2);
        return Padding(
          padding: const EdgeInsets.all(SdbSpacing.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Mỗi hàng là một khung phổ (mới nhất ở trên), trục ngang là tần số log 20 Hz - ${formatHz(nyquist)}.',
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final hz in const [20.0, 100.0, 1000.0, 10000.0])
                if (hz <= nyquist) Text(formatHz(hz), style: TextStyle(color: p.chartAxis, fontSize: 11)),
            ]),
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
    return ListenableBuilder(
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
                message: 'Dải thấp nhất chỉ phủ ${formatNumber(minBins)} bin FFT - tăng kích thước FFT '
                    '(Thiết lập phổ) để dải tần thấp chính xác hơn.',
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
            Text('Mức dải (IEC 61260-1, hệ cơ số 10) trọng số ${services.settings.weighting.label}, từ phổ trung bình.',
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
          const Text('Thiết lập phổ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: SdbSpacing.s3),
          DropdownButtonFormField<int>(
            initialValue: settings.fftSize,
            decoration: const InputDecoration(labelText: 'Kích thước FFT'),
            items: [for (final n in Settings.fftSizes) DropdownMenuItem(value: n, child: Text('$n mẫu'))],
            onChanged: (v) => settings.setFft(v!, settings.window),
          ),
          const SizedBox(height: SdbSpacing.s3),
          DropdownButtonFormField<WindowKind>(
            initialValue: settings.window,
            decoration: const InputDecoration(labelText: 'Cửa sổ'),
            items: [for (final w in WindowKind.values) DropdownMenuItem(value: w, child: Text(w.label))],
            onChanged: (v) => settings.setFft(settings.fftSize, v!),
          ),
          const SizedBox(height: SdbSpacing.s3),
          Text('Thang hiển thị: ${formatNumber(settings.spectrumMinDb, digits: 0)} - ${formatNumber(settings.spectrumMaxDb, digits: 0)} dB'),
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
