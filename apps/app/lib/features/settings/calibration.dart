import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';
import 'package:uuid/uuid.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../services/measurement.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';

enum CalibrationMethod {
  calibrator94('Máy hiệu chuẩn 94 dB @ 1 kHz', 94, 'calibrator_94'),
  calibrator114('Máy hiệu chuẩn 114 dB @ 1 kHz', 114, 'calibrator_114'),
  reference('So với máy đo chuẩn (nhập số đọc)', null, 'reference_meter');

  const CalibrationMethod(this.label, this.referenceDb, this.code);
  final String label;
  final double? referenceDb;
  final String code;
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
      if (mounted) showMessage(context, m.error ?? 'Không mở được micro.');
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
    showMessage(context, 'Đã áp dụng offset ${formatDb(newOffset, digits: 2)}.');
    Navigator.pop(context);
    unawaited(services.sync.syncNow(onlyIfAuto: true));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final current = services.settings.calibrationOffsetDb;
    final reference = _method.referenceDb ?? parseNumber(_referenceController.text);
    final newOffset = (_measured != null && reference != null) ? reference - (_measured! - current) : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Hiệu chuẩn micro')),
      body: ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
        Text('Offset hiện tại: ${formatDb(current, digits: 2)}${services.settings.calibrated ? '' : ' (mặc định, chưa hiệu chuẩn)'}'),
        const SizedBox(height: SdbSpacing.s4),
        RadioGroup<CalibrationMethod>(
          groupValue: _method,
          onChanged: (v) => setState(() {
            _method = v!;
            _measured = null;
          }),
          child: Column(children: [
            for (final m in CalibrationMethod.values) RadioListTile<CalibrationMethod>(value: m, title: Text(m.label)),
          ]),
        ),
        const SizedBox(height: SdbSpacing.s2),
        Text(
          _method == CalibrationMethod.reference
              ? 'Đặt điện thoại sát máy đo chuẩn, cùng hướng về nguồn ồn ổn định (quạt, ồn hồng). '
                  'Đo 10 giây rồi nhập LAeq mà máy chuẩn hiển thị trong cùng khoảng thời gian.'
              : 'Lắp đầu micro vào khớp nối của máy hiệu chuẩn (hoặc áp sát nếu không vừa), bật máy hiệu chuẩn, '
                  'giữ yên rồi bấm Đo. Kết quả dùng LZeq 10 giây.',
        ),
        if (_method == CalibrationMethod.reference) ...[
          const SizedBox(height: SdbSpacing.s3),
          TextField(
            controller: _referenceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'LAeq của máy đo chuẩn (dB)'),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: SdbSpacing.s4),
        FilledButton.icon(
          onPressed: _remaining > 0 ? null : _measure,
          icon: const Icon(Icons.mic),
          label: Text(_remaining > 0 ? 'Đang đo... còn $_remaining giây' : 'Đo $measureSeconds giây'),
        ),
        if (_measured != null) ...[
          const SizedBox(height: SdbSpacing.s3),
          Text('Đo được: ${formatDb(_measured!, digits: 2)} (với offset cũ)'),
          if (newOffset != null) ...[
            Text('Offset mới: ${formatDb(newOffset, digits: 2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: SdbSpacing.s2),
            FilledButton(onPressed: () => _apply(newOffset, _method.code), child: const Text('Áp dụng')),
          ],
        ],
        const Divider(height: SdbSpacing.s8),
        const Text('Nhập offset thủ công', style: TextStyle(fontWeight: FontWeight.w600)),
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
              if (v == null || v < 0 || v > 200) return showMessage(context, 'Offset phải là số trong 0-200 dB.');
              _apply(v, 'manual');
            },
            child: const Text('Áp dụng'),
          ),
        ]),
        const SizedBox(height: SdbSpacing.s3),
        TextButton(
          onPressed: () async {
            await services.settings.setCalibration(120, calibrated: false);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Khôi phục mặc định (bỏ hiệu chuẩn)'),
        ),
      ]),
    );
  }
}
