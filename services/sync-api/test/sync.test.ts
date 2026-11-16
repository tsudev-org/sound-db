import { describe, expect, it } from 'vitest';

import { cleanup } from '../src/maintenance';
import { env } from 'cloudflare:test';
import { appLogin, call, fakeIdp } from './helpers';

const session = (label: string, startedAt = '2026-11-17T08:00:00.000Z') => ({
  v: 1,
  started_at: startedAt,
  duration_s: 61.5,
  label,
  note: '',
  summary: { laeq: 62.3, lceq: 70.1, lzeq: 74, lafmax: 80.2, lafmin: 45.1, lasmax: 77, lcpeak: 95.5, l10: 66, l50: 60, l90: 50, dose_niosh: 0.1, dose_osha: 0.01, twa_niosh: 50, sel_a: 80.2 },
  series: { interval_s: 1, laeq: [60.1, 61.2, null] },
  third_octave_lzeq: { '1000.0': 55.2, '31.5': 40 },
  calibration_offset_db: 118.5,
  device_model: 'Pixel 9',
  platform: 'android',
});

async function login(sub: string) {
  const idp = await fakeIdp({ sub });
  const { body } = await appLogin(idp);
  return { Authorization: `Bearer ${body.access_token}`, 'content-type': 'application/json' };
}

describe('đồng bộ', () => {
  it('đẩy, kéo theo con trỏ, ghi sau thắng, bia mộ', async () => {
    const a = await login('sync-user');
    const id = crypto.randomUUID();
    const push = async (changes: unknown[]) =>
      (await (await call('/api/v1/sync/push', { method: 'POST', headers: a, body: JSON.stringify({ changes }) })).json()) as any;

    let r = await push([{ kind: 'session', id, updated_at: 1_790_000_000_000, deleted: false, data: session('Phòng khách') }]);
    expect(r.results[0].status).toBe('applied');

    // Bản cũ hơn bị coi là lỗi thời và nhận lại bản máy chủ.
    r = await push([{ kind: 'session', id, updated_at: 1_700_000_000_000, deleted: false, data: session('Cũ') }]);
    expect(r.results[0].status).toBe('stale');
    expect(r.results[0].record.data.label).toBe('Phòng khách');

    // Dữ liệu sai lược đồ bị từ chối riêng từng bản ghi.
    r = await push([{ kind: 'session', id: crypto.randomUUID(), updated_at: 1_790_000_000_000, deleted: false, data: { ...session('x'), hack: 1 } }]);
    expect(r.results[0].status).toBe('rejected');

    const pull = (since: number) => call(`/api/v1/sync/pull?since=${since}&limit=1`, { headers: a }).then((x) => x.json()) as Promise<any>;
    const p1 = await pull(0);
    expect(p1.changes).toHaveLength(1);
    expect(p1.has_more).toBe(false);

    // Thiết bị thứ hai (cùng tài khoản) thấy bản ghi và xóa nó.
    const b = await login('sync-user');
    const del = (await (await call('/api/v1/sync/push', {
      method: 'POST', headers: b,
      body: JSON.stringify({ changes: [{ kind: 'session', id, updated_at: 1_790_000_000_001, deleted: true, data: {} }] }),
    })).json()) as any;
    expect(del.results[0].status).toBe('applied');
    const p2 = await pull(p1.cursor);
    expect(p2.changes[0].deleted).toBe(true);
    expect(p2.changes[0].data).toEqual({});
  });

  it('cô lập người dùng: không đọc được dữ liệu người khác', async () => {
    const a = await login('owner-a');
    const id = crypto.randomUUID();
    await call('/api/v1/sync/push', { method: 'POST', headers: a, body: JSON.stringify({ changes: [{ kind: 'session', id, updated_at: 1_790_000_000_000, deleted: false, data: session('Riêng tư') }] }) });
    const b = await login('owner-b');
    expect((await call(`/api/v1/sessions/${id}`, { headers: b })).status).toBe(404);
    const pulled = (await (await call('/api/v1/sync/pull', { headers: b })).json()) as any;
    expect(pulled.changes).toHaveLength(0);
  });

  it('danh sách phiên phân trang theo bộ mốc chuẩn, tìm theo nhãn', async () => {
    const a = await login('pager');
    const changes = Array.from({ length: 23 }, (_, i) => ({
      kind: 'session', id: crypto.randomUUID(), updated_at: 1_790_000_000_000, deleted: false,
      data: session(i === 5 ? 'Công trường 50%' : `Phiên ${i}`, new Date(Date.UTC(2026, 10, 1, 0, i)).toISOString()),
    }));
    await call('/api/v1/sync/push', { method: 'POST', headers: a, body: JSON.stringify({ changes }) });
    const page = (await (await call('/api/v1/sessions?page=3&page_size=10', { headers: a })).json()) as any;
    expect(page.total).toBe(23);
    expect(page.items).toHaveLength(3);
    const odd = (await (await call('/api/v1/sessions?page_size=25', { headers: a })).json()) as any;
    expect(odd.page_size).toBe(10);
    const search = (await (await call('/api/v1/sessions?q=50%25', { headers: a })).json()) as any;
    expect(search.total).toBe(1);
    expect(search.items[0].label).toBe('Công trường 50%');
  });

  it('thu hồi thiết bị chặn ngay access token của nó', async () => {
    const a = await login('revoker');
    const me = (await (await call('/api/v1/me', { headers: a })).json()) as any;
    const res = await call(`/api/v1/me/devices/${me.current_device_id}`, { method: 'DELETE', headers: a });
    expect(res.status).toBe(204);
    expect((await call('/api/v1/me', { headers: a })).status).toBe(401);
  });

  it('dọn dữ liệu hết hạn không lỗi', async () => {
    await cleanup(env, Date.now() + 400 * 24 * 3600 * 1000);
  });
});
