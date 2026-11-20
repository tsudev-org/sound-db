// Máy đo trên trình duyệt (/do/): micro → AudioWorklet → lõi DSP WebAssembly → giao diện.
import { decodeLevels, loadEngine, type WasmEngine } from './dsp';
import { d, thapPhan } from './i18n';

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const KHOA_OFFSET = 'sounddb.web.offset';
const OFFSET_MAC_DINH = 100;
const TEN_TS = ['A', 'C', 'Z'];
const TEN_TG = ['F', 'S', 'I'];

let engine: WasmEngine | null = null;
let ctx: AudioContext | null = null;
let stream: MediaStream | null = null;
let trongSo = 0;
let thoiGian = 0;
let lanVe = 0;

function docOffset(): number {
  try {
    const v = Number(localStorage.getItem(KHOA_OFFSET));
    return Number.isFinite(v) && v > 0 && v < 200 ? v : OFFSET_MAC_DINH;
  } catch {
    return OFFSET_MAC_DINH;
  }
}

const so = (v: number | undefined, chuSo = 1) => (v === undefined || !Number.isFinite(v) ? '-' : thapPhan(v, chuSo));
const hz = (v: number) => (!Number.isFinite(v) ? '-' : v >= 1000 ? `${so(v / 1000, 3)} kHz` : `${so(v, 1)} Hz`);
const thoiLuong = (s: number) => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

function baoLoi(chu: string) {
  const el = $('loi');
  el.textContent = chu;
  el.hidden = false;
}

async function batDau() {
  const nut = $<HTMLButtonElement>('nut-do');
  nut.disabled = true;
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false, channelCount: 1 },
    });
    ctx = new AudioContext();
    await ctx.audioWorklet.addModule('/worklet/thu-am.js');
    engine = await loadEngine(ctx.sampleRate, docOffset());
    const nguon = ctx.createMediaStreamSource(stream);
    const nut2 = new AudioWorkletNode(ctx, 'thu-am');
    nut2.port.onmessage = (e: MessageEvent<Float32Array>) => engine?.push(e.data);
    nguon.connect(nut2);
    nut.textContent = d.do.dung;
    nut.disabled = false;
    $<HTMLButtonElement>('nut-dat-lai').disabled = false;
    requestAnimationFrame(ve);
  } catch (e) {
    nut.disabled = false;
    const ten = (e as DOMException).name;
    baoLoi(
      ten === 'NotAllowedError'
        ? d.do.loiQuyen
        : ten === 'NotFoundError'
          ? d.do.loiKhongMicro
          : d.do.loiKhoiDong,
    );
    await dung();
  }
}

async function dung() {
  stream?.getTracks().forEach((t) => t.stop());
  stream = null;
  await ctx?.close().catch(() => {});
  ctx = null;
  engine?.free();
  engine = null;
  $('nut-do').textContent = d.do.batDau;
  $<HTMLButtonElement>('nut-dat-lai').disabled = true;
}

function veCanvas(pho: Float32Array, binHz: number, dinhHz: number) {
  const c = $<HTMLCanvasElement>('pho');
  const dpr = window.devicePixelRatio || 1;
  const w = c.clientWidth;
  const h = c.clientHeight;
  if (c.width !== Math.round(w * dpr)) {
    c.width = Math.round(w * dpr);
    c.height = Math.round(h * dpr);
  }
  const g = c.getContext('2d')!;
  g.setTransform(dpr, 0, 0, dpr, 0, 0);
  const css = getComputedStyle(document.documentElement);
  const mau = (ten: string) => css.getPropertyValue(ten).trim();
  g.clearRect(0, 0, w, h);
  const fMin = 20;
  const fMax = Math.min(20000, binHz * (pho.length - 1));
  const x = (f: number) => (w * Math.log(f / fMin)) / Math.log(fMax / fMin);
  const dbMin = 0;
  const dbMax = 120;
  const y = (db: number) => h * (1 - (Math.min(Math.max(db, dbMin), dbMax) - dbMin) / (dbMax - dbMin));
  g.strokeStyle = mau('--chart-grid');
  g.fillStyle = mau('--chart-axis');
  g.font = '11px sans-serif';
  g.lineWidth = 1;
  for (const f of [50, 100, 200, 500, 1000, 2000, 5000, 10000]) {
    if (f > fMax) continue;
    g.beginPath();
    g.moveTo(x(f), 0);
    g.lineTo(x(f), h);
    g.stroke();
    g.fillText(f >= 1000 ? `${f / 1000}k` : String(f), x(f) + 2, h - 4);
  }
  for (let db = 20; db < dbMax; db += 20) {
    g.beginPath();
    g.moveTo(0, y(db));
    g.lineTo(w, y(db));
    g.stroke();
    g.fillText(String(db), 2, y(db) - 2);
  }
  g.beginPath();
  let lastX = -1;
  let cot = -Infinity;
  for (let k = 1; k < pho.length; k++) {
    const f = k * binHz;
    if (f < fMin) continue;
    if (f > fMax) break;
    cot = Math.max(cot, pho[k]!);
    const px = x(f);
    if (px - lastX >= 1) {
      lastX < 0 ? g.moveTo(px, y(cot)) : g.lineTo(px, y(cot));
      lastX = px;
      cot = -Infinity;
    }
  }
  g.strokeStyle = mau('--chart-line');
  g.lineWidth = 1.5;
  g.stroke();
  if (Number.isFinite(dinhHz) && dinhHz >= fMin) {
    g.strokeStyle = mau('--chart-peak');
    g.beginPath();
    g.moveTo(x(dinhHz), 0);
    g.lineTo(x(dinhHz), h);
    g.stroke();
  }
}

function ve(t: number) {
  if (!engine) return;
  requestAnimationFrame(ve);
  if (t - lanVe < 50) return;
  lanVe = t;
  const m = decodeLevels(engine.levels());
  if (m.elapsed < 0.2) return;
  const muc = m.instant[trongSo]![thoiGian]!;
  const out = $<HTMLOutputElement>('muc');
  out.value = so(muc);
  out.dataset.vung = muc >= 85 ? 'nguy' : muc >= 70 ? 'luu-y' : 'an-toan';
  $('nhan-muc').textContent = `L${TEN_TS[trongSo]}${TEN_TG[thoiGian]}`;
  $('don-vi').textContent = `dB(${TEN_TS[trongSo]})`;
  $('leq').textContent = so(m.leq[trongSo]);
  $('lmax').textContent = so(m.max[trongSo]![thoiGian]);
  $('lmin').textContent = so(m.min[trongSo]![thoiGian]);
  $('lpeak').textContent = so(m.peak[trongSo]);
  $('l10').textContent = so(m.percentiles[2]);
  $('l90').textContent = so(m.percentiles[4]);
  $('thoi-luong').textContent = thoiLuong(m.elapsed);
  const pho = engine.spectrum(trongSo, false);
  const dinh = engine.dominantPeak(20, 20000);
  $('tan-so').textContent = dinh.length ? hz(dinh[0]!) : '-';
  veCanvas(pho, engine.binHz(), dinh.length ? dinh[0]! : NaN);
}

function chonNhom(attr: string, gan: (v: number) => void) {
  document.querySelectorAll<HTMLButtonElement>(`[${attr}]`).forEach((b) =>
    b.addEventListener('click', () => {
      document.querySelectorAll<HTMLButtonElement>(`[${attr}]`).forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
      gan(Number(b.getAttribute(attr)));
    }),
  );
}

$('offset-hien').textContent = so(docOffset());
$('nut-do').addEventListener('click', () => (engine ? dung() : batDau()));
$('nut-dat-lai').addEventListener('click', () => engine?.resetSession());
chonNhom('data-trong-so', (v) => (trongSo = v));
chonNhom('data-thoi-gian', (v) => (thoiGian = v));
$('nut-offset').addEventListener('click', () => {
  const v = Number($<HTMLInputElement>('offset').value.replace(',', '.'));
  if (!Number.isFinite(v) || v <= 0 || v >= 200) return baoLoi(d.do.loiOffset);
  try {
    localStorage.setItem(KHOA_OFFSET, String(v));
  } catch {
    /* trình duyệt chặn lưu: vẫn áp dụng cho phiên này */
  }
  engine?.setCalibration(v);
  $('offset-hien').textContent = so(v);
});
if (!window.isSecureContext || !navigator.mediaDevices || !('AudioWorkletNode' in window)) {
  baoLoi(d.do.loiKhongHoTro);
  $<HTMLButtonElement>('nut-do').disabled = true;
}
