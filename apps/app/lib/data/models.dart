import 'dart:convert';

/// Một phiên đo đã lưu. `data` là phần đồng bộ lên máy chủ (JSON, giới hạn
/// kích thước ở `services/sync-api`), các trường còn lại là siêu dữ liệu đồng bộ.
class MeasurementSession {
  MeasurementSession({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    required this.label,
    required this.note,
    required this.summary,
    required this.seriesLaeq,
    required this.thirdOctaveLzeq,
    required this.calibrationOffsetDb,
    required this.deviceModel,
    required this.platform,
    required this.updatedAt,
    this.deleted = false,
    this.dirty = true,
  });

  final String id;
  final DateTime startedAt;
  final double durationSeconds;
  String label;
  String note;

  /// Khóa: laeq, lceq, lzeq, lafmax, lafmin, lasmax, lcpeak, l10, l50, l90, dose_niosh, dose_osha, twa_niosh, sel_a.
  final Map<String, double?> summary;

  /// LAeq theo từng giây (0,1 dB), tối đa 7200 điểm - phiên dài hơn được gộp.
  final List<double> seriesLaeq;

  /// LZeq trung bình theo dải 1/3 octave: {danh định Hz: dB}.
  final Map<String, double> thirdOctaveLzeq;
  final double calibrationOffsetDb;
  final String deviceModel;
  final String platform;
  DateTime updatedAt;
  bool deleted;
  bool dirty;

  static const int maxSeriesPoints = 7200;

  Map<String, Object?> toData() => {
        'v': 1,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_s': durationSeconds,
        'label': label,
        'note': note,
        'summary': summary,
        'series': {'interval_s': seriesIntervalSeconds, 'laeq': seriesLaeq},
        'third_octave_lzeq': thirdOctaveLzeq,
        'calibration_offset_db': calibrationOffsetDb,
        'device_model': deviceModel,
        'platform': platform,
      };

  double get seriesIntervalSeconds =>
      seriesLaeq.isEmpty ? 1 : (durationSeconds / seriesLaeq.length).clamp(1, double.infinity).toDouble();

  static MeasurementSession fromData(
    String id,
    Map<String, Object?> data, {
    required DateTime updatedAt,
    bool deleted = false,
    bool dirty = false,
  }) {
    double? asDouble(Object? v) => v is num ? v.toDouble() : null;
    final series = (data['series'] as Map<String, Object?>?) ?? const {};
    return MeasurementSession(
      id: id,
      startedAt: DateTime.tryParse(data['started_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      durationSeconds: asDouble(data['duration_s']) ?? 0,
      label: (data['label'] as String?) ?? '',
      note: (data['note'] as String?) ?? '',
      summary: {
        for (final e in ((data['summary'] as Map<String, Object?>?) ?? const {}).entries) e.key: asDouble(e.value),
      },
      seriesLaeq: [for (final v in (series['laeq'] as List<Object?>?) ?? const []) asDouble(v) ?? double.nan],
      thirdOctaveLzeq: {
        for (final e in ((data['third_octave_lzeq'] as Map<String, Object?>?) ?? const {}).entries)
          if (asDouble(e.value) != null) e.key: asDouble(e.value)!,
      },
      calibrationOffsetDb: asDouble(data['calibration_offset_db']) ?? 0,
      deviceModel: (data['device_model'] as String?) ?? '',
      platform: (data['platform'] as String?) ?? '',
      updatedAt: updatedAt,
      deleted: deleted,
      dirty: dirty,
    );
  }

  String toJsonString() => jsonEncode(toData());

  /// CSV: phần tóm tắt rồi chuỗi LAeq theo thời gian.
  String toCsv() {
    final b = StringBuffer()
      ..writeln('khoa,gia_tri')
      ..writeln('bat_dau,${startedAt.toIso8601String()}')
      ..writeln('thoi_luong_s,$durationSeconds')
      ..writeln('nhan,"${label.replaceAll('"', '""')}"')
      ..writeln('hieu_chuan_offset_db,$calibrationOffsetDb');
    summary.forEach((k, v) => b.writeln('$k,${v ?? ''}'));
    b
      ..writeln()
      ..writeln('giay,laeq_db');
    for (var i = 0; i < seriesLaeq.length; i++) {
      b.writeln('${(i * seriesIntervalSeconds).toStringAsFixed(0)},${seriesLaeq[i].toStringAsFixed(1)}');
    }
    b
      ..writeln()
      ..writeln('dai_1_3_octave_hz,lzeq_db');
    thirdOctaveLzeq.forEach((hz, db) => b.writeln('$hz,${db.toStringAsFixed(1)}'));
    return b.toString();
  }
}

/// Hồ sơ hiệu chuẩn theo thiết bị/micro.
class CalibrationProfile {
  CalibrationProfile({
    required this.id,
    required this.name,
    required this.offsetDb,
    required this.method,
    required this.updatedAt,
    this.deleted = false,
    this.dirty = true,
  });

  final String id;
  String name;
  double offsetDb;

  /// `manual` | `calibrator_94` | `calibrator_114` | `reference_meter`.
  String method;
  DateTime updatedAt;
  bool deleted;
  bool dirty;

  Map<String, Object?> toData() => {'v': 1, 'name': name, 'offset_db': offsetDb, 'method': method};

  static CalibrationProfile fromData(String id, Map<String, Object?> d,
          {required DateTime updatedAt, bool deleted = false, bool dirty = false}) =>
      CalibrationProfile(
        id: id,
        name: (d['name'] as String?) ?? 'Hồ sơ',
        offsetDb: (d['offset_db'] as num?)?.toDouble() ?? 0,
        method: (d['method'] as String?) ?? 'manual',
        updatedAt: updatedAt,
        deleted: deleted,
        dirty: dirty,
      );
}
