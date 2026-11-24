// Bảng điều khiển: gọi API cùng gốc bằng cookie phiên (HttpOnly). Mọi lệnh ghi gửi header chống CSRF.
// Chữ từ máy chủ chỉ gán qua textContent, không bao giờ qua innerHTML.
import { d, den, dien, lang, ngay as ngayX, ngayGio, thapPhan } from './i18n';

const j = d.js;
const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const SIZES = [10, 20, 50, 100, 200];
const KHOA_SO_DONG = 'tsudev.pagesize.sound-db-sessions';

interface Pro { active: boolean; pro_until: number; cloud_delete_after: number | null; badge: string }
interface Me { display_name: string; email: string | null; stats: { sessions: number; calibrations: number; measured_seconds: number }; pro: Pro | null }
interface SessionRow { id: string; label: string; started_at: string; duration_s: number; laeq: number | null; lafmax: number | null }
interface Device { id: string; name: string; platform: string; last_seen_at: number }

async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set('Accept', 'application/json');
  if (init.method && init.method !== 'GET') headers.set('X-Sdb-Csrf', '1');
  const res = await fetch(path, { ...init, headers, credentials: 'same-origin' });
  if (res.status === 204) return undefined as T;
  const body = await res.json().catch(() => ({ message: dien(j.loiHttp, { x: res.status }) }));
  // Thông báo lỗi của máy chủ là tiếng Việt ⇒ trang tiếng Anh dùng câu chung kèm mã lỗi.
  const msg = lang === 'vi' ? body.message : body.code ? `${j.thatBai} (${body.code})` : undefined;
  if (!res.ok) throw Object.assign(new Error(msg ?? j.loi), { status: res.status });
  return body as T;
}

const hai = (n: number) => String(n).padStart(2, '0');
const so = (v: number | null) => (v === null || !Number.isFinite(v) ? '-' : thapPhan(v, 1));
const ngay = (s: number) => ngayX(new Date(s * 1000));
const thoiLuong = (s: number) => `${Math.floor(s / 3600)}:${hai(Math.floor((s % 3600) / 60))}:${hai(Math.floor(s % 60))}`;

function o(text: string, cls?: string) {
  const td = document.createElement('td');
  td.textContent = text;
  if (cls) td.className = cls;
  return td;
}

const state = { page: 1, size: 10, total: 0, q: '', khoang: 'tat-ca', tu: '', den: '' };
const KHOANG = ['tat-ca', '7n', '30n', '1y', 'tuy-chon'];

/** Khoảng [date_from, date_to) theo giờ địa phương của người xem (SEARCH_AND_FILTER.md mục 6.1, 7). */
function khoangNgay(): { from?: string; to?: string } {
  const homNay = new Date();
  homNay.setHours(0, 0, 0, 0);
  const lui = (ngay: number, thang = 0, nam = 0) =>
    new Date(homNay.getFullYear() - nam, homNay.getMonth() - thang, homNay.getDate() - ngay).toISOString();
  switch (state.khoang) {
    case '7n': return { from: lui(6) };
    case '30n': return { from: lui(0, 1) };
    case '1y': return { from: lui(0, 0, 1) };
    case 'tuy-chon': {
      const ngay = (v: string, them = 0) => {
        const [y, m, dd] = v.split('-').map(Number);
        return new Date(y, m - 1, dd + them).toISOString();
      };
      return { from: state.tu ? ngay(state.tu) : undefined, to: state.den ? ngay(state.den, 1) : undefined };
    }
    default: return {};
  }
}
let luotTai = 0; // chỉ hiển thị phản hồi của lượt tải MỚI NHẤT (bấm nhanh không bị phản hồi cũ đè)

function baoLoi(e: unknown) {
  const el = $('thong-bao');
  el.textContent = (e as Error)?.message || j.thatBai;
  el.hidden = false;
  if ((e as { status?: number }).status === 401) location.href = den('/dang-nhap/');
}

/** Bọc thao tác của người dùng: lỗi hiện thành thông báo, không thành lỗi ngầm. */
const an = (fn: () => Promise<unknown>) => () => {
  $('thong-bao').hidden = true;
  fn().catch(baoLoi);
};

function docSoDong(): number {
  const tuUrl = Number(new URLSearchParams(location.search).get('page_size'));
  if (SIZES.includes(tuUrl)) return tuUrl;
  try {
    const v = Number(localStorage.getItem(KHOA_SO_DONG));
    return SIZES.includes(v) ? v : 10;
  } catch {
    return 10;
  }
}

async function taiPhien() {
  const luot = ++luotTai;
  const sel = $<HTMLSelectElement>('so-dong');
  sel.disabled = true;
  const qs = new URLSearchParams({ page: String(state.page), page_size: String(state.size) });
  if (state.q) qs.set('q', state.q);
  const { from, to } = khoangNgay();
  if (from) qs.set('date_from', from);
  if (to) qs.set('date_to', to);
  // Từ khoá + bộ lọc nằm trên URL (mục 6.4): chia sẻ được, tải lại giữ nguyên.
  const url = new URLSearchParams({ page: String(state.page), page_size: String(state.size) });
  if (state.q) url.set('q', state.q);
  if (state.khoang !== 'tat-ca') url.set('khoang', state.khoang);
  if (state.khoang === 'tuy-chon' && state.tu) url.set('tu', state.tu);
  if (state.khoang === 'tuy-chon' && state.den) url.set('den', state.den);
  history.replaceState(null, '', `?${url}`);
  try {
    const r = await api<{ items: SessionRow[]; total: number }>(`/api/v1/sessions?${qs}`);
    if (luot !== luotTai) return;
    state.total = r.total;
    const body = $('dong-phien');
    body.replaceChildren(
      ...r.items.map((s) => {
        const tr = document.createElement('tr');
        tr.append(o(s.label || j.phienDo), o(ngayGio(new Date(s.started_at))), o(thoiLuong(s.duration_s), 'so'), o(so(s.laeq), 'so'), o(so(s.lafmax), 'so'));
        const td = document.createElement('td');
        const xoa = document.createElement('button');
        xoa.className = 'nut nut--phu nut--nho';
        xoa.type = 'button';
        xoa.textContent = j.xoa;
        xoa.addEventListener('click', an(async () => {
          if (!confirm(dien(j.xacNhanXoaPhien, { x: s.label }))) return;
          await api(`/api/v1/sessions/${encodeURIComponent(s.id)}`, { method: 'DELETE' });
          await taiPhien();
        }));
        td.append(xoa);
        tr.append(td);
        return tr;
      }),
    );
    if (!r.items.length) {
      const tr = document.createElement('tr');
      const td = o(state.q.length >= 2 ? dien(j.khongKhopTu, { x: state.q }) : state.khoang !== 'tat-ca' ? j.khongKhop : j.chuaCoPhien);
      td.colSpan = 6;
      tr.append(td);
      body.append(tr);
    }
    const trang = Math.max(1, Math.ceil(state.total / state.size));
    const dau = state.total ? (state.page - 1) * state.size + 1 : 0;
    $('tom-tat').textContent = `${dau}-${Math.min(state.page * state.size, state.total)} / ${state.total}`;
    $('so-trang').textContent = `${state.page} / ${trang}`;
    $<HTMLButtonElement>('truoc').disabled = state.page <= 1;
    $<HTMLButtonElement>('sau').disabled = state.page >= trang;
  } finally {
    sel.disabled = false;
  }
}

async function taiThietBi() {
  const r = await api<{ devices: Device[] }>('/api/v1/me/devices');
  $('dong-thiet-bi').replaceChildren(
    ...r.devices.map((d) => {
      const tr = document.createElement('tr');
      tr.append(o(d.name), o(d.platform), o(ngayGio(new Date(d.last_seen_at))));
      const td = document.createElement('td');
      const b = document.createElement('button');
      b.className = 'nut nut--phu nut--nho';
      b.type = 'button';
      b.textContent = j.dangXuatThietBi;
      b.addEventListener('click', an(async () => {
        if (!confirm(dien(j.xacNhanDangXuat, { x: d.name }))) return;
        await api(`/api/v1/me/devices/${encodeURIComponent(d.id)}`, { method: 'DELETE' });
        await Promise.all([taiThietBi(), taiHoatDong()]);
      }));
      td.append(b);
      tr.append(td);
      return tr;
    }),
  );
}

const TEN_SU_KIEN = j.suKien;

async function taiHoatDong() {
  const r = await api<{ events: { event: string; at: number }[] }>('/api/v1/me/activity');
  $('dong-hoat-dong').replaceChildren(
    ...r.events.map((e) => {
      const tr = document.createElement('tr');
      tr.append(o(TEN_SU_KIEN[e.event] ?? e.event), o(ngayGio(new Date(e.at))));
      return tr;
    }),
  );
}

/** Trạng thái TsuDEV Pro (PRODUCT_POLICY 7.2): mua/gia hạn ở tsudev.com, không nhúng thanh toán vào trang này. */
function hienPro(pro: Pro | null, coDuLieu: boolean) {
  const el = $('trang-thai-pro');
  if (!pro) {
    el.textContent = j.proLoi;
    return;
  }
  const bayGio = Date.now() / 1000;
  if (pro.active) {
    el.textContent = dien(j.proToi, { x: ngay(pro.pro_until) });
    $('nut-pro').textContent = j.giaHan;
  } else {
    el.textContent = j.proMienPhi;
  }
  if (!pro.active && coDuLieu && pro.cloud_delete_after && pro.cloud_delete_after > bayGio) {
    const xoa = $('han-xoa');
    xoa.textContent = dien(j.hanXoa, { x: ngay(pro.cloud_delete_after) });
    xoa.hidden = false;
  }
}

async function khoiDong() {
  try {
    const trangThai = await api<{ signed_in: boolean }>('/api/v1/auth/status');
    if (!trangThai.signed_in) {
      $('trang-thai').hidden = true;
      $('chua-dang-nhap').hidden = false;
      return;
    }
    const me = await api<Me>('/api/v1/me');
    $('trang-thai').hidden = true;
    $('da-dang-nhap').hidden = false;
    $('ten').textContent = me.display_name;
    $('email').textContent = me.email ?? '';
    $('thong-ke').textContent = dien(j.thongKe, { a: me.stats.sessions, b: me.stats.calibrations, c: thoiLuong(me.stats.measured_seconds) });
    hienPro(me.pro, me.stats.sessions + me.stats.calibrations > 0);
    state.size = docSoDong();
    const tham = new URLSearchParams(location.search);
    state.page = Math.max(1, Number(tham.get('page')) || 1);
    state.q = (tham.get('q') ?? '').slice(0, 100);
    state.khoang = KHOANG.includes(tham.get('khoang') ?? '') ? (tham.get('khoang') as string) : 'tat-ca';
    const ngayHopLe = (v: string | null) => (v && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : '');
    state.tu = ngayHopLe(tham.get('tu'));
    state.den = ngayHopLe(tham.get('den'));
    $<HTMLInputElement>('tim').value = state.q;
    $<HTMLSelectElement>('khoang').value = state.khoang;
    $<HTMLInputElement>('tu-ngay').value = state.tu;
    $<HTMLInputElement>('den-ngay').value = state.den;
    $('khoang-tuy-chon').hidden = state.khoang !== 'tuy-chon';
    $<HTMLSelectElement>('so-dong').value = String(state.size);
    await Promise.all([taiPhien(), taiThietBi(), taiHoatDong()]);
  } catch (e) {
    if ((e as { status?: number }).status === 401) {
      $('trang-thai').hidden = true;
      $('chua-dang-nhap').hidden = false;
    } else {
      $('trang-thai').textContent = dien(j.khongTai, { x: (e as Error).message });
    }
  }
}

$<HTMLSelectElement>('so-dong').addEventListener('change', (ev) => {
  const moi = Number((ev.target as HTMLSelectElement).value);
  // Giữ bản ghi đầu đang nhìn thấy (DATA_TABLE.md mục 4).
  state.page = Math.floor(((state.page - 1) * state.size) / moi) + 1;
  state.size = SIZES.includes(moi) ? moi : 10;
  try {
    localStorage.setItem(KHOA_SO_DONG, String(state.size));
  } catch {
    /* bỏ qua */
  }
  an(taiPhien)();
});
$('truoc').addEventListener('click', () => { state.page = Math.max(1, state.page - 1); an(taiPhien)(); });
$('sau').addEventListener('click', () => { state.page++; an(taiPhien)(); });
let hen: number | undefined;
$('tim').addEventListener('input', (ev) => {
  clearTimeout(hen);
  hen = window.setTimeout(() => {
    state.q = (ev.target as HTMLInputElement).value.trim();
    state.page = 1;
    an(taiPhien)();
  }, 350);
});
$('khoang').addEventListener('change', (ev) => {
  state.khoang = (ev.target as HTMLSelectElement).value;
  $('khoang-tuy-chon').hidden = state.khoang !== 'tuy-chon';
  state.page = 1;
  an(taiPhien)();
});
for (const [id, khoa] of [['tu-ngay', 'tu'], ['den-ngay', 'den']] as const) {
  $(id).addEventListener('change', (ev) => {
    state[khoa] = (ev.target as HTMLInputElement).value;
    state.page = 1;
    an(taiPhien)();
  });
}
$('nut-xuat').addEventListener('click', () => { location.href = '/api/v1/me/export'; });
$('nut-dang-xuat').addEventListener('click', an(async () => {
  await api('/api/v1/auth/web-logout', { method: 'POST' });
  location.href = den('/');
}));
$('nut-xoa').addEventListener('click', an(async () => {
  const go = prompt(j.nhapXacNhan);
  if (go === null) return;
  if (go.trim() !== 'xoa-vinh-vien') throw new Error(j.sai);
  await api('/api/v1/me', { method: 'DELETE', headers: { 'X-Sdb-Confirm': 'xoa-vinh-vien' } });
  location.href = den('/');
}));
void khoiDong();
