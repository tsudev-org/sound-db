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
  if (!/<link rel="canonical" href="https:\/\/sound\.tsudev\.com\//.test(html)) loi.push(`${ten}: thiếu canonical`);
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
  const lang = html.match(/<html lang="(vi|en)" data-theme="dark"/)?.[1];
  if (!lang) loi.push(`${ten}: cần <html lang="vi|en" data-theme="dark">`);
  else if ((lang === 'en') !== ten.startsWith('/en/')) loi.push(`${ten}: lang="${lang}" lệch thư mục`);
  // PRODUCT_POLICY mục 1: lang.js nạp chặn trong <head> (tự chọn ngôn ngữ lần đầu), trang có bản dịch phải có hreflang đủ.
  const viTriLang = html.indexOf('<script src="/lang.js">');
  if (viTriLang < 0 || viTriLang > html.indexOf('</head>')) loi.push(`${ten}: thiếu lang.js trong <head>`);
  if (!html.includes('data-mot-ngon-ngu')) {
    for (const h of ['vi', 'en', 'x-default']) if (!html.includes(`hreflang="${h}"`)) loi.push(`${ten}: thiếu hreflang ${h}`);
    if (!/data-chon-ngon-ngu="vi"[\s\S]*data-chon-ngon-ngu="en"/.test(html)) loi.push(`${ten}: thiếu bộ chọn ngôn ngữ`);
  }
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
for (const f of ['theme.js', 'lang.js', 'wasm/sounddb_dsp.js', 'wasm/sounddb_dsp_bg.wasm', 'worklet/thu-am.js', 'favicon.svg', 'favicon.ico', 'favicon-96x96.png', 'apple-touch-icon.png', 'og-image.png', '.well-known/security.txt']) {
  if (!existsSync(join(dist, f))) loi.push(`thiếu dist/${f}`);
}
// Điều khoản Pro đứng trước nút mua, NGUYÊN VĂN PRODUCT_POLICY mục 7.5 (vi), {giá} = 490.000 ₫ (mục 7.2).
const chinhSach = readFileSync(join(dirname(fileURLToPath(import.meta.url)), '../../../.standards/docs/PRODUCT_POLICY.md'), 'utf8');
const DIEU_KHOAN = {
  vi: { mau: /nguyên văn \(vi\): "([^"]+)"/, gia: '{giá}', trang: 'bang-dieu-khien/index.html' },
  en: { mau: /- \(en\): "([^"]+)"/, gia: '{price}', trang: 'en/bang-dieu-khien/index.html' },
};
for (const [ma, { mau, gia, trang }] of Object.entries(DIEU_KHOAN)) {
  const dieuKhoan = chinhSach.match(mau)?.[1]?.replace(/\s*\n\s*/g, ' ').replace(gia, '490.000 ₫');
  const bang = readFileSync(join(dist, trang), 'utf8');
  const dk = bang.match(/<p class="dieu-khoan" id="dieu-khoan-pro">([^<]*)<\/p>/)?.[1];
  if (!dieuKhoan) loi.push(`PRODUCT_POLICY: không tìm thấy điều khoản 7.5 (${ma})`);
  else if (dk !== dieuKhoan) loi.push(`${trang}: điều khoản Pro lệch nguyên văn 7.5 (${ma}):\n    trang:  ${dk}\n    chuẩn: ${dieuKhoan}`);
  else if (bang.indexOf('id="dieu-khoan-pro"') > bang.indexOf('id="nut-pro"')) loi.push(`${trang}: điều khoản Pro phải đứng TRƯỚC nút mua`);
}
const DONG = ['/auth/', '/api/'];
for (const [ten, duong] of lienKet) {
  if (DONG.some((d) => duong.startsWith(d))) continue;
  const dich = join(dist, duong);
  if (!existsSync(dich) && !existsSync(join(dich, 'index.html'))) loi.push(`${ten}: liên kết gãy ${duong}`);
}
// SEC2 / RFC 9116: security.txt còn hạn và hạn ≤ 1 năm (tính từ lúc build - CI đỏ trước khi tệp hết hạn), Contact đầu
// tiên là security@tsudev.com, Policy trỏ /security/. Mẫu: tsudev test/securityTxt.test.ts.
const secTxt = readFileSync(join(dist, '.well-known/security.txt'), 'utf8');
const het = Date.parse(secTxt.match(/^Expires:\s*(\S+)/m)?.[1] ?? '');
const NAM = 365 * 24 * 3600 * 1000;
if (!Number.isFinite(het)) loi.push('security.txt: thiếu/sai Expires');
else if (het <= Date.now()) loi.push(`security.txt: Expires đã qua (${new Date(het).toISOString()}) - gia hạn`);
else if (het - Date.now() > NAM + 24 * 3600 * 1000) loi.push('security.txt: Expires xa hơn 1 năm (RFC 9116 khuyên < 1 năm)');
if (secTxt.match(/^Contact:\s*(\S+)/m)?.[1] !== 'mailto:security@tsudev.com') loi.push('security.txt: Contact đầu tiên phải là mailto:security@tsudev.com');
if (!/^Policy: https:\/\/sound\.tsudev\.com\/security\/$/m.test(secTxt)) loi.push('security.txt: Policy phải trỏ /security/');
// SEC2: mỗi bằng chứng có liên kết https của bên thứ ba + ngày đo thật (không ở tương lai, không chỗ trống chờ điền);
// trang /security (vi + en) hiện đủ mục.
const tin = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), '../../../docs/security/trust.json'), 'utf8'));
for (const e of tin.evidence) {
  if (!/^https:\/\//.test(e.url ?? '')) loi.push(`trust.json ${e.id}: thiếu liên kết kiểm chứng https`);
  const d = Date.parse(e.measured ?? '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(e.measured ?? '') || !(d <= Date.now() + 24 * 3600 * 1000)) loi.push(`trust.json ${e.id}: ngày đo sai ${e.measured}`);
  if (!e.status || /PENDING|TODO/i.test(e.status)) loi.push(`trust.json ${e.id}: chưa có kết quả đo thật`);
}
for (const [trang, chu] of [['security/index.html', 'Báo lỗ hổng'], ['en/security/index.html', 'Report a vulnerability']]) {
  const html = readFileSync(join(dist, trang), 'utf8');
  if (!html.includes(chu) || !html.includes('mailto:security@tsudev.com')) loi.push(`${trang}: thiếu mục ${chu}`);
  for (const e of tin.evidence) if (!html.includes(e.url.replace(/&/g, '&amp;'))) loi.push(`${trang}: thiếu liên kết ${e.id}`);
}
if (loi.length) {
  console.error(`check-dist: ${loi.length} lỗi\n  ${loi.join('\n  ')}`);
  process.exit(1);
}
console.log('check-dist: đạt.');
