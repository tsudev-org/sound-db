import { expect, it } from 'vitest';
import { sessionData } from '../src/sync/schema';
it('lược đồ phiên đo nhận bản ghi tối thiểu hợp lệ', () => {
  const r = sessionData.safeParse({
    v: 1, started_at: '2026-11-17T08:00:00.000Z', duration_s: 61.5, label: 'x', note: '',
    summary: { laeq: 62.3 }, series: { interval_s: 1, laeq: [60.1, null] }, third_octave_lzeq: { '1000.0': 55.2 },
    calibration_offset_db: 118.5, device_model: 'P', platform: 'android',
  });
  expect(r.success ? 'ok' : JSON.stringify(r.error.issues)).toBe('ok');
});
