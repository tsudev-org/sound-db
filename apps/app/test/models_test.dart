import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/data/models.dart';

void main() {
  test('phiên đo khứ hồi qua dữ liệu đồng bộ', () {
    final s = MeasurementSession(
      id: '0190a1b2-0000-7000-8000-000000000001',
      startedAt: DateTime.utc(2026, 11, 17, 8),
      durationSeconds: 61.5,
      label: 'Phòng "khách"',
      note: '',
      summary: {'laeq': 62.3, 'lafmax': null},
      seriesLaeq: [60.1, 61.2],
      thirdOctaveLzeq: {'1000.0': 55.2},
      calibrationOffsetDb: 118.5,
      deviceModel: 'Pixel 9',
      platform: 'android',
      updatedAt: DateTime.utc(2026, 11, 17, 9),
    );
    final back = MeasurementSession.fromData(s.id, s.toData(), updatedAt: s.updatedAt);
    expect(back.label, s.label);
    expect(back.summary['laeq'], 62.3);
    expect(back.summary['lafmax'], isNull);
    expect(back.seriesLaeq, [60.1, 61.2]);
    expect(back.startedAt.toUtc(), s.startedAt);
    expect(s.toCsv(), contains('nhan,"Phòng ""khách"""'));
    expect(s.toData()['v'], 1);
  });
}
