// Công cụ rà giao diện UI2 (phiếu logs/handover/20261125-UI2_*); Playwright mượn của repo tsudev (đặt PLAYWRIGHT=... để đổi).
// Đo size-adjust / ascent / descent của font web so với Arimo (≡ Arial). node metrics.cjs
const path = require('path');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT || path.join(process.env.HOME, 'projects/tsudev/node_modules/playwright'));
// ARIMO = thư mục giải nén của `npm pack @fontsource/arimo@5` (đặt ngoài repo, chỉ đọc tệp font).
const ARIMO = process.env.ARIMO || '.';
const W = path.join(__dirname, '../../apps/web/public/fonts');
const b64 = (p) => fs.readFileSync(p).toString('base64');
const faces = [
  ['SG', 500, `${W}/space-grotesk-500-latin.woff2`, `${W}/space-grotesk-500-vietnamese.woff2`],
  ['SG', 700, `${W}/space-grotesk-700-latin.woff2`, `${W}/space-grotesk-700-vietnamese.woff2`],
  ['BVP', 400, `${W}/be-vietnam-pro-400-latin.woff2`, `${W}/be-vietnam-pro-400-vietnamese.woff2`],
  ['BVP', 700, `${W}/be-vietnam-pro-700-latin.woff2`, `${W}/be-vietnam-pro-700-vietnamese.woff2`],
  ['AR', 400, `${ARIMO}/package/files/arimo-latin-400-normal.woff2`],
  ['AR', 700, `${ARIMO}/package/files/arimo-latin-700-normal.woff2`],
];
const css = faces
  .flatMap(([f, w, ...files]) => files.map((p) => `@font-face{font-family:${f};font-weight:${w};src:url(data:font/woff2;base64,${b64(p)})}`))
  .join('\n');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.setContent(`<style>${css}</style><p style="font-family:SG,BVP,AR">x</p>`);
  const res = await page.evaluate(async () => {
    const text = 'Đo âm thanh chính xác, trên mọi thiết bị. Sound Db đo mức âm, phổ tần số 1/3 octave 0123456789 dB(A)';
    const latin = 'Measure sound accurately, on every device. Sound level meter 0123456789 dB(A)';
    await document.fonts.load('700 20px SG'); await document.fonts.load('500 20px SG');
    await document.fonts.load('400 20px BVP'); await document.fonts.load('700 20px BVP');
    await document.fonts.load('400 20px AR'); await document.fonts.load('700 20px AR');
    const c = document.createElement('canvas').getContext('2d');
    const m = (fam, w, t) => { c.font = `${w} 100px ${fam}`; const x = c.measureText(t); return { w: x.width, a: x.fontBoundingBoxAscent, d: x.fontBoundingBoxDescent }; };
    const out = {};
    for (const [fam, w, arW] of [['SG', 500, 400], ['SG', 700, 700], ['BVP', 400, 400], ['BVP', 700, 700]]) {
      const f = m(fam, w, text), r = m('AR', arW, text), fl = m(fam, w, latin), rl = m('AR', arW, latin);
      const size = f.w / r.w;
      out[`${fam} ${w}`] = { sizeAdjustVi: (100 * size).toFixed(1), sizeAdjustLatin: (100 * fl.w / rl.w).toFixed(1), ascent: (100 * f.a / 100 / size).toFixed(1), descent: (100 * f.d / 100 / size).toFixed(1), rawAscent: f.a, rawDescent: f.d };
    }
    return out;
  });
  console.log(JSON.stringify(res, null, 1));
  await browser.close();
})();
