import { env } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

import { verifyAndPurge } from '../src/pro/purge';
import { appLogin, call, fakeIdp } from './helpers';

const DAY = 24 * 3600 * 1000;
const nowS = () => Math.floor(Date.now() / 1000);

const session = (label: string) => ({
  v: 1,
  started_at: '2026-11-17T08:00:00.000Z',
  duration_s: 30,
  label,
  note: '',
  summary: { laeq: 62.3, lceq: 70.1, lzeq: 74, lafmax: 80.2, lafmin: 45.1, lasmax: 77, lcpeak: 95.5, l10: 66, l50: 60, l90: 50, dose_niosh: 0.1, dose_osha: 0.01, twa_niosh: 50, sel_a: 80.2 },
  series: { interval_s: 1, laeq: [60.1] },
  third_octave_lzeq: {},
  calibration_offset_db: 118.5,
  device_model: 'Pixel 9',
  platform: 'android',
});

async function setup(sub: string, proUntil?: number) {
  const idp = await fakeIdp({ sub, proUntil });
  const { body } = await appLogin(idp);
  const headers = { Authorization: `Bearer ${body.access_token}`, 'content-type': 'application/json' };
  const user = await env.DB.prepare('SELECT id FROM users WHERE oidc_sub = ?').bind(sub).first<{ id: string }>();
  return { idp, headers, userId: user!.id };
}

const push = (headers: Record<string, string>, label = 'Phòng đo') =>
  call('/api/v1/sync/push', {
    method: 'POST',
    headers,
    body: JSON.stringify({ changes: [{ kind: 'session', id: crypto.randomUUID(), updated_at: Date.now(), deleted: false, data: session(label) }] }),
  });

const countRecords = async (userId: string) =>
  (await env.DB.prepare('SELECT COUNT(*) AS n FROM records WHERE user_id = ?').bind(userId).first<{ n: number }>())!.n;

describe('gate Pro ở máy chủ (PRODUCT_POLICY 7.1 N4, 7.4)', () => {
  it('chưa có Pro ⇒ đẩy bị 402 pro_required, KHÔNG ghi gì; kéo vẫn được', async () => {
    const { headers, userId } = await setup('free-user', 0);
    const res = await push(headers);
    expect(res.status).toBe(402);
    expect(await res.json()).toMatchObject({ error: 'pro_required' });
    expect(await countRecords(userId)).toBe(0);
    expect((await call('/api/v1/sync/pull?since=0', { headers })).status).toBe(200);
  });

  it('có Pro ⇒ đẩy được; quyền lợi đệm trong 24 giờ (không hỏi lại tsudev.com mỗi lượt)', async () => {
    const { idp, headers } = await setup('pro-user');
    expect((await push(headers)).status).toBe(200);
    const calls = idp.rpCalls;
    expect((await push(headers)).status).toBe(200);
    expect(idp.rpCalls).toBe(calls);
  });

  it('trang Tài khoản (/api/v1/me) hiện Pro thật và lưu đệm quyền lợi (sự cố 21/11 entitlements_unavailable)', async () => {
    const until = nowS() + 200 * 24 * 3600;
    const { headers, userId } = await setup('acct-user', until);
    const res = await call('/api/v1/me', { headers });
    expect(res.status).toBe(200);
    const me = (await res.json()) as { pro: { active: boolean; pro_until: number } | null };
    expect(me.pro).toMatchObject({ active: true, pro_until: until });
    const row = await env.DB.prepare('SELECT pro_until FROM entitlements WHERE user_id = ?').bind(userId).first<{ pro_until: number }>();
    expect(row?.pro_until).toBe(until * 1000);

    const free = await setup('acct-free', 0);
    const meFree = (await (await call('/api/v1/me', { headers: free.headers })).json()) as { pro: { active: boolean } | null };
    expect(meFree.pro).toMatchObject({ active: false });
  });

  it('kênh RP trả chuyển hướng ⇒ không đi theo, coi là lỗi (503 khi hết đệm), không phải miễn phí', async () => {
    const { idp, headers, userId } = await setup('redir-user');
    await env.DB.prepare('DELETE FROM entitlements WHERE user_id = ?').bind(userId).run();
    idp.redirectRp = true;
    const res = await push(headers);
    expect(res.status).toBe(503);
    expect(await res.json()).toMatchObject({ error: 'entitlements_unavailable' });
  });

  it('Pro hết hạn ⇒ 402', async () => {
    const { headers } = await setup('expired-user', nowS() - 3600);
    expect((await push(headers)).status).toBe(402);
  });

  it('chưa cấu hình khoá RP ⇒ không ai là Pro (402), không gọi tsudev.com', async () => {
    const { idp, headers } = await setup('no-rp-user');
    delete (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK;
    const before = idp.rpCalls;
    expect((await push(headers)).status).toBe(402);
    expect(idp.rpCalls).toBe(before);
  });

  for (const [name, override] of [
    ['sai aud', (s: any) => s({ pro_until: nowS() + 9999, badge: 'pro', devices_30d: 1 }, { aud: 'app-khac' })],
    ['hết hạn', (s: any) => s({ pro_until: nowS() + 9999, badge: 'pro', devices_30d: 1 }, { iat: nowS() - 8 * 86400, exp: nowS() - 86400 })],
    ['sai chữ ký', (s: any) => s({ pro_until: nowS() + 9999, badge: 'pro', devices_30d: 1 }, { foreignKey: true })],
    ['sai typ', (s: any) => s({ pro_until: nowS() + 9999, badge: 'pro', devices_30d: 1 }, { typ: 'JWT' })],
    ['exp quá 7 ngày', (s: any) => s({ pro_until: nowS() + 9999, badge: 'pro', devices_30d: 1 }, { exp: nowS() + 30 * 86400 })],
  ] as const) {
    it(`JWS ${name} bị từ chối ⇒ không coi là Pro, không ghi`, async () => {
      const { idp, headers, userId } = await setup(`bad-jws-${name}`);
      idp.jwsOverride = override as never;
      const res = await push(headers);
      expect(res.status).toBe(503);
      expect(res.headers.get('Retry-After')).toBe('300');
      expect(await countRecords(userId)).toBe(0);
    });
  }

  it('tsudev.com lỗi: còn đệm < 24 giờ ⇒ dùng đệm; hết đệm ⇒ 503 entitlements_unavailable', async () => {
    const { headers, userId } = await setup('outage-user');
    expect((await push(headers)).status).toBe(200);
    // tsudev.com sập (khoá RP sai ⇒ 401 invalid_client) - đệm vẫn còn hạn.
    await env.DB.prepare('UPDATE entitlements SET fetched_at = ? WHERE user_id = ?').bind(Date.now() - 23 * 3600 * 1000, userId).run();
    const good = (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK;
    (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK = JSON.stringify({ kty: 'EC', crv: 'P-256', x: 'IELA3vloIxxB2s1JfSXdkFX3Jpp1TaUY4Cf0VucFM8Y', y: 'Qhx7koHCNs7FArdh5poFdK70yge-6Q-gsPAwoLeQOJg', d: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE' });
    await env.DB.prepare('UPDATE entitlements SET fetched_at = ? WHERE user_id = ?').bind(Date.now() - 25 * 3600 * 1000, userId).run();
    const res = await push(headers);
    expect([503]).toContain(res.status);
    expect(await res.json()).toMatchObject({ error: 'entitlements_unavailable' });
    (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK = good;
  });

  it('grant OIDC hết hạn (kênh RP 404) ⇒ dùng kênh trạng thái cho pro_until', async () => {
    const { idp, headers } = await setup('no-grant-user');
    idp.grant = false;
    const ent = await call('/api/v1/me/entitlements', { headers });
    expect(ent.status).toBe(200);
    const body = (await ent.json()) as any;
    expect(body.jws).toBeNull();
    expect(body.active).toBe(true);
    expect(idp.statusCalls).toBe(1);
    expect((await push(headers)).status).toBe(200);
  });

  it('/me/entitlements: JWS gốc + chuyển X-Tsu-Installation; client assertion đúng iss/sub/aud, jti một lần', async () => {
    const { idp, headers } = await setup('ent-user');
    const inst = 'AAAAAAAAAAAAAAAAAAAAAA';
    const res = await call('/api/v1/me/entitlements', { headers: { ...headers, 'X-Tsu-Installation': inst, 'X-Tsu-Platform': 'android' } });
    const body = (await res.json()) as any;
    expect(res.status).toBe(200);
    expect(body.jws.split('.')).toHaveLength(3);
    expect(body).toMatchObject({ active: true, badge: 'pro', devices_30d: 2, buy_url: 'https://tsudev.com/pro?app=sounddb' });
    expect(idp.lastHeaders?.get('X-Tsu-Installation')).toBe(inst);
    expect(idp.lastHeaders?.get('X-Tsu-Platform')).toBe('android');
    // Mã cài đặt sai khuôn không được chuyển đi.
    await call('/api/v1/me/entitlements', { headers: { ...headers, 'X-Tsu-Installation': 'x'.repeat(40) } });
    expect(idp.lastHeaders?.get('X-Tsu-Installation')).toBeNull();
    const jtis = idp.assertions.map((a) => a.jti);
    expect(new Set(jtis).size).toBe(jtis.length);
    for (const a of idp.assertions) expect(a).toMatchObject({ iss: 'sounddb', sub: 'sounddb', kid: 'sounddb-rp-test' });
  });

  it('web không sửa được phiên đo trên đám mây khi không có Pro (402); xoá vẫn được', async () => {
    const { idp, headers, userId } = await setup('web-edit-user');
    expect((await push(headers)).status).toBe(200);
    const id = (await env.DB.prepare('SELECT id FROM records WHERE user_id = ?').bind(userId).first<{ id: string }>())!.id;
    idp.proUntil = nowS() - 10;
    await env.DB.prepare('UPDATE entitlements SET fetched_at = 0 WHERE user_id = ?').bind(userId).run();
    const patch = await call(`/api/v1/sessions/${id}`, { method: 'PATCH', headers, body: JSON.stringify({ label: 'Mới' }) });
    expect(patch.status).toBe(402);
    expect((await call(`/api/v1/sessions/${id}`, { method: 'DELETE', headers })).status).toBe(204);
  });
});

describe('xoá có xác minh (PRODUCT_POLICY 7.4 kênh trạng thái, phiếu PRO2 2.3)', () => {
  /** Tài khoản có dữ liệu, rồi Pro hết hạn từ `daysAgo` ngày trước (đệm cục bộ ghi hạn cũ). */
  async function expiredAccount(sub: string, daysAgo: number) {
    const s = await setup(sub);
    expect((await push(s.headers)).status).toBe(200);
    const old = Date.now() - daysAgo * DAY;
    await env.DB.prepare('UPDATE entitlements SET pro_until = ?, fetched_at = 0, purge_checked_at = 0 WHERE user_id = ?').bind(old, s.userId).run();
    s.idp.proUntil = Math.floor(old / 1000);
    return s;
  }

  it('hết hạn thật quá 90 ngày ⇒ xoá', async () => {
    const { userId } = await expiredAccount('purge-real', 91);
    const r = await verifyAndPurge(env);
    expect(r.purged).toBeGreaterThanOrEqual(1);
    expect(await countRecords(userId)).toBe(0);
    const log = await env.DB.prepare("SELECT detail FROM audit_log WHERE user_id = ? AND event = 'cloud_purged'").bind(userId).first<{ detail: string }>();
    expect(log?.detail).toBe('pro_expired_90d');
  });

  it('gia hạn trên web mà không mở app ⇒ KHÔNG xoá + cập nhật hạn', async () => {
    const { idp, userId } = await expiredAccount('purge-renewed', 120);
    idp.proUntil = nowS() + 300 * 86400; // tsudev.com biết đã gia hạn; máy chủ này chỉ có hạn cũ.
    await verifyAndPurge(env);
    expect(await countRecords(userId)).toBe(1);
    const e = await env.DB.prepare('SELECT pro_until FROM entitlements WHERE user_id = ?').bind(userId).first<{ pro_until: number }>();
    expect(e!.pro_until).toBe(idp.proUntil * 1000);
  });

  it('kênh lỗi ⇒ hoãn, không hỏi lại trong 24 giờ, sau 24 giờ hỏi lại', async () => {
    const { idp, userId } = await expiredAccount('purge-error', 100);
    idp.status = 'error';
    await verifyAndPurge(env);
    expect(await countRecords(userId)).toBe(1);
    const calls = idp.statusCalls;
    await verifyAndPurge(env, Date.now() + 3600 * 1000);
    expect(idp.statusCalls).toBe(calls);
    idp.status = 'ok';
    await verifyAndPurge(env, Date.now() + 25 * 3600 * 1000);
    expect(idp.statusCalls).toBe(calls + 1);
    expect(await countRecords(userId)).toBe(0);
  });

  it('unknown_subject ⇒ hoãn, không xoá', async () => {
    const { idp, userId } = await expiredAccount('purge-unknown', 100);
    idp.status = 'unknown_subject';
    const r = await verifyAndPurge(env);
    expect(r.deferred).toBeGreaterThanOrEqual(1);
    expect(await countRecords(userId)).toBe(1);
  });

  it('deleted ⇒ xoá', async () => {
    const { idp, userId } = await expiredAccount('purge-deleted', 10);
    // Chưa quá 90 ngày theo đệm ⇒ chưa là ứng viên, không hỏi.
    const calls = idp.statusCalls;
    await verifyAndPurge(env);
    expect(idp.statusCalls).toBe(calls);
    expect(await countRecords(userId)).toBe(1);
    await env.DB.prepare('UPDATE entitlements SET pro_until = ? WHERE user_id = ?').bind(Date.now() - 95 * DAY, userId).run();
    idp.status = 'deleted';
    await verifyAndPurge(env);
    expect(await countRecords(userId)).toBe(0);
  });

  it('chưa cấu hình khoá RP ⇒ không xoá gì, không gọi kênh trạng thái', async () => {
    const { idp, userId } = await expiredAccount('purge-no-rp', 200);
    delete (env as { RP_PRIVATE_JWK?: string }).RP_PRIVATE_JWK;
    const calls = idp.statusCalls;
    const r = await verifyAndPurge(env);
    expect(r).toEqual({ checked: 0, kept: 0, purged: 0, deferred: 0 });
    expect(idp.statusCalls).toBe(calls);
    expect(await countRecords(userId)).toBe(1);
  });
});
