import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:uuid/uuid.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../services/measurement.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';

enum CalibrationMethod {
  calibrator94(94, 'calibrator_94'),
  calibrator114(114, 'calibrator_114'),
  reference(null, 'reference_meter');

  const CalibrationMethod(this.referenceDb, this.code);
  final double? referenceDb;
  final String code;

  String label(AppLocalizations l) => switch (this) {
        calibrator94 => l.calMethod94,
        calibrator114 => l.calMethod114,
        reference => l.calMethodReference,
      };
}

/// Hiệu chuẩn: đo LZeq (máy hiệu chuẩn) hoặc LAeq (máy đo chuẩn) trong 10 giây,
/// offset mới = mức chuẩn - (mức đo được - offset cũ).
class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  static const measureSeconds = 10;
  CalibrationMethod _method = CalibrationMethod.calibrator94;
  final _referenceController = TextEditingController();
  final _manualController = TextEditingController();
  Timer? _timer;
  int _remaining = 0;
  double? _measured;

  @override
  void dispose() {
    _timer?.cancel();
    _referenceController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _measure() async {
    final m = AppScope.of(context).measurement;
    if (m.state != MeterState.running) await m.start();
    if (m.state != MeterState.running) {
      if (mounted) showMessage(context, m.error ?? context.l10n.micOpenFailed);
      return;
    }
    m.resetSession();
    setState(() {
      _remaining = measureSeconds;
      _measured = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        final s = m.engine.meter.snapshot();
        final w = _method == CalibrationMethod.reference ? Weighting.a : Weighting.z;
        setState(() => _measured = s.leq[w.index]);
      }
    });
  }

  Future<void> _apply(double newOffset, String method) async {
    final services = AppScope.of(context);
    await services.settings.setCalibration(newOffset, calibrated: true);
    await services.store.saveCalibration(CalibrationProfile(
      id: const Uuid().v7(),
      name: '${services.deviceModel} - ${formatDateTime(DateTime.now())}',
      offsetDb: newOffset,
      method: method,
      updatedAt: DateTime.now().toUtc(),
    ));
    if (!mounted) return;
    showMessage(context, context.l10n.offsetApplied(formatDb(newOffset, digits: 2)));
    Navigator.pop(context);
    unawaited(services.sync.syncNow(onlyIfAuto: true));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final current = services.settings.calibrationOffsetDb;
    final reference = _method.referenceDb ?? parseNumber(_referenceController.text);
    final newOffset = (_measured != null && reference != null) ? reference - (_measured! - current) : null;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.micCalibration)),
      body: ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
        Text(services.settings.calibrated
            ? l.currentOffset(formatDb(current, digits: 2))
            : l.currentOffsetDefault(formatDb(current, digits: 2))),
        const SizedBox(height: SdbSpacing.s4),
        RadioGroup<CalibrationMethod>(
          groupValue: _method,
          onChanged: (v) => setState(() {
            _method = v!;
            _measured = null;
          }),
          child: Column(children: [
            for (final m in CalibrationMethod.values) RadioListTile<CalibrationMethod>(value: m, title: Text(m.label(l))),
          ]),
        ),
        const SizedBox(height: SdbSpacing.s2),
        Text(
          _method == CalibrationMethod.reference
              ? l.calReferenceHowTo
              : l.calCalibratorHowTo,
        ),
        if (_method == CalibrationMethod.reference) ...[
          const SizedBox(height: SdbSpacing.s3),
          TextField(
            controller: _referenceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.referenceLaeq),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: SdbSpacing.s4),
        FilledButton.icon(
          onPressed: _remaining > 0 ? null : _measure,
          icon: const Icon(Icons.mic),
          label: Text(_remaining > 0 ? l.measuringRemaining('$_remaining') : l.measureSeconds('$measureSeconds')),
        ),
        if (_measured != null) ...[
          const SizedBox(height: SdbSpacing.s3),
          Text(l.measuredWithOld(formatDb(_measured!, digits: 2))),
          if (newOffset != null) ...[
            Text(l.newOffset(formatDb(newOffset, digits: 2)), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: SdbSpacing.s2),
            FilledButton(onPressed: () => _apply(newOffset, _method.code), child: Text(l.apply)),
          ],
        ],
        const Divider(height: SdbSpacing.s8),
        Text(l.manualOffset, style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: SdbSpacing.s2),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _manualController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Offset (dB)'),
            ),
          ),
          const SizedBox(width: SdbSpacing.s2),
          OutlinedButton(
            onPressed: () {
              final v = parseNumber(_manualController.text);
              if (v == null || v < 0 || v > 200) return showMessage(context, l.offsetRange);
              _apply(v, 'manual');
            },
            child: Text(l.apply),
          ),
        ]),
        const SizedBox(height: SdbSpacing.s3),
        TextButton(
          onPressed: () async {
            await services.settings.setCalibration(120, calibrated: false);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.restoreDefault),
        ),
      ]),
    );
  }
}
