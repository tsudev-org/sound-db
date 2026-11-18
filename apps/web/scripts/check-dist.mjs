// Kiểm bản build (ECOSYSTEM_IDENTITY.md mục 2.2 và 4): title đúng khuôn, og:site_name = TsuDEV, canonical,
// description 120-160 ký tự, KHÔNG script/CSS nội tuyến (CSP script-src/style-src 'self'), theme.js nạp chặn trước
// stylesheet, bộ chọn giao diện đúng hợp đồng, liên kết mở tab mới có rel đủ, không em-dash/en-dash, liên kết nội bộ không gãy.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = join(dirname(fileURLToPath(import.meta.url)), '../dist');
const loi = [];
const lienKet = [];
function duyet(thuMuc) {
  for (const e of readdirSync(thuMuc, { withFileTypes: true })) {
    const p = join(thuMuc, e.name);
    if (e.isDirectory()) duyet(p);
    else if (e.name.endsWith('.html')) kiemTra(p, readFileSync(p, 'utf8'));
  }
}
function kiemTra(tep, html) {
  const ten = tep.slice(dist.length);
  const title = html.match(/<title>([^<]*)<\/title>/)?.[1] ?? '';
  if (!/^(.+ - )?Sound Db \| TsuDEV$/.test(title)) loi.push(`${ten}: title sai khuôn: ${title}`);
  if (!html.includes('<meta property="og:site_name" content="TsuDEV">')) loi.push(`${ten}: thiếu og:site_name TsuDEV`);
  if (!/<link rel="canonical" href="https:\/\/sounddb\.tsudev\.com\//.test(html)) loi.push(`${ten}: thiếu canonical`);
  const mota = html.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? '';
  const dai = [...mota.replace(/&[a-z#0-9]+;/g, 'x')].length;
  if (dai < 120 || dai > 160) loi.push(`${ten}: description ${dai} ký tự (cần 120-160)`);
  const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/g)];
  for (const [, attrs, body] of scripts) {
    if (!/\bsrc="\//.test(attrs) || body.trim()) loi.push(`${ten}: script nội tuyến (CSP chặn): ${attrs}`);
  }
  const viTriTheme = html.indexOf('<script src="/theme.js">');
  const viTriCss = html.search(/<link[^>]*rel="stylesheet"/);
  if (viTriTheme < 0 || viTriTheme > html.indexOf('</head>') || (viTriCss >= 0 && viTriTheme > viTriCss)) loi.push(`${ten}: theme.js phải nằm trong <head>, trước stylesheet`);
  const luaChon = [...html.matchAll(/data-chon-giao-dien="([a-z]+)"/g)].map((m) => m[1]).join(',');
  if (luaChon !== 'light,dark,system') loi.push(`${ten}: bộ chọn giao diện cần light,dark,system: ${luaChon}`);
  if (html.indexOf('id="giao-dien"') < html.indexOf('<footer')) loi.push(`${ten}: bộ chọn giao diện phải ở chân trang`);
  if (!/<html lang="vi" data-theme="dark">/.test(html)) loi.push(`${ten}: mặc định phải là data-theme="dark"`);
  if (/<style[\s>]/.test(html) || / style="/.test(html)) loi.push(`${ten}: có CSS nội tuyến (CSP chặn)`);
  for (const a of html.matchAll(/<a [^>]*target="_blank"[^>]*>/g)) {
    if (!a[0].includes('rel="noopener noreferrer"')) loi.push(`${ten}: thiếu rel noopener noreferrer`);
  }
  const chu = html.replace(/<pre[\s\S]*?<\/pre>/g, '').replace(/<script[\s\S]*?<\/script>/g, '').replace(/<[^>]+>/g, ' ');
  if (/[\u2013\u2014]/.test(chu)) loi.push(`${ten}: có em-dash/en-dash trong chữ hiển thị`);
  for (const m of html.matchAll(/(?:href|src)="(\/[^"#?]*)/g)) lienKet.push([ten, m[1]]);
}
duyet(dist);
const csp = readFileSync(join(dist, '_headers'), 'utf8').match(/Content-Security-Policy:\s*(.+)/)?.[1] ?? '';
if (!/script-src 'self'(;| )/.test(csp)) loi.push(`_headers: CSP cần script-src 'self': ${csp}`);
if (/'unsafe-(inline|eval)'/.test(csp)) loi.push(`_headers: CSP không được có 'unsafe-inline'/'unsafe-eval'`);
for (const f of ['theme.js', 'wasm/sounddb_dsp.js', 'wasm/sounddb_dsp_bg.wasm', 'worklet/thu-am.js', 'favicon.ico', 'favicon-96x96.png', 'apple-touch-icon.png', 'og-image.png', '.well-known/security.txt']) {
  if (!existsSync(join(dist, f))) loi.push(`thiếu dist/${f}`);
}
const DONG = ['/auth/', '/api/'];
for (const [ten, duong] of lienKet) {
  if (DONG.some((d) => duong.startsWith(d))) continue;
  const dich = join(dist, duong);
  if (!existsSync(dich) && !existsSync(join(dich, 'index.html'))) loi.push(`${ten}: liên kết gãy ${duong}`);
}
if (loi.length) {
  console.error(`check-dist: ${loi.length} lỗi\n  ${loi.join('\n  ')}`);
  process.exit(1);
}
console.log('check-dist: đạt.');
