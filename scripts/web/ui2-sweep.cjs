// Công cụ rà giao diện UI2 (phiếu logs/handover/20261125-UI2_*); Playwright mượn của repo tsudev (đặt PLAYWRIGHT=... để đổi).
// UI2 phần A: quét mọi trang × 3 khổ × Sáng/Tối. node sweep.cjs <gốc> [trang...]
const path = require('path');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT || path.join(process.env.HOME, 'projects/tsudev/node_modules/playwright'));
const base = process.argv[2];
const pages = process.argv.slice(3);
const out = path.join(process.env.OUT || path.join(__dirname, '../../logs/qa/ui2'), 'sweep');
fs.mkdirSync(out, { recursive: true });
(async () => {
  const browser = await chromium.launch();
  const report = [];
  for (const scheme of ['light', 'dark']) {
    for (const width of [360, 768, 1366]) {
      const ctx = await browser.newContext({ viewport: { width, height: 800 }, colorScheme: scheme, locale: 'vi-VN' });
      for (const p of pages) {
        const page = await ctx.newPage();
        const errs = [];
        page.on('console', (m) => { if (m.type() === 'error' && !m.text().includes('404')) errs.push(m.text().slice(0, 160)); });
        page.on('pageerror', (e) => errs.push('pageerror ' + e.message.slice(0, 160)));
        page.on('response', (r) => { if (r.status() >= 400 && !r.url().includes('/api/')) errs.push(`HTTP ${r.status()} ${r.url()}`); });
        await page.goto(base + p, { waitUntil: 'networkidle' }).catch((e) => errs.push('goto ' + e.message));
        const info = await page.evaluate(() => {
          const vw = document.documentElement.clientWidth;
          const over = [];
          for (const el of document.querySelectorAll('body *')) {
            const r = el.getBoundingClientRect();
            const cs = getComputedStyle(el);
            if (r.width === 0 || cs.visibility === 'hidden' || cs.display === 'none') continue;
            if ((r.right > vw + 1 || r.left < -1) && !el.classList.contains('bo-qua')) {
              let a = el.parentElement, clipped = false;
              while (a) { const s = getComputedStyle(a); if (/(auto|scroll|hidden|clip)/.test(s.overflowX)) { clipped = true; break; } a = a.parentElement; }
              if (!clipped) over.push(`${el.tagName.toLowerCase()}.${[...el.classList].join('.')} r=${Math.round(r.right)}`);
            }
          }
          const imgs = [...document.images].filter((i) => i.complete && i.naturalWidth === 0).map((i) => i.src);
          const theme = document.documentElement.dataset.theme;
          const bg = getComputedStyle(document.body).backgroundColor;
          const emdash = (document.body.innerText.match(/[—–]/g) || []).length;
          return { scrollW: document.documentElement.scrollWidth, vw, over: over.slice(0, 5), imgs, theme, bg, emdash };
        });
        // Bàn phím: 12 lần Tab, phần tử nhận focus phải có viền focus nhìn thấy.
        const noRing = [];
        for (let i = 0; i < 12; i++) {
          await page.keyboard.press('Tab');
          const f = await page.evaluate(() => {
            const e = document.activeElement;
            if (!e || e === document.body) return null;
            const s = getComputedStyle(e);
            const ring = (s.outlineStyle !== 'none' && parseFloat(s.outlineWidth) > 0) || s.boxShadow !== 'none';
            return ring ? null : `${e.tagName.toLowerCase()} "${(e.textContent || e.getAttribute('aria-label') || '').trim().slice(0, 30)}"`;
          });
          if (f) noRing.push(f);
        }
        if (width !== 768 && (p === '' || p === 'do/')) {
          await page.keyboard.press('Escape');
          await page.screenshot({ path: path.join(out, `${scheme}-${width}-${p.replace(/\//g, '_') || 'home'}.png`), fullPage: true });
        }
        const bad = info.scrollW > info.vw || info.over.length || info.imgs.length || errs.length || noRing.length || info.emdash;
        report.push(`${bad ? 'LỖI' : 'ok '} ${scheme} ${width} /${p} theme=${info.theme} bg=${info.bg}` +
          (bad ? ` | scrollW=${info.scrollW}/${info.vw} over=${JSON.stringify(info.over)} img=${info.imgs.length} emdash=${info.emdash} noRing=${JSON.stringify([...new Set(noRing)])} err=${JSON.stringify(errs.slice(0, 4))}` : ''));
        await page.close();
      }
      await ctx.close();
    }
  }
  console.log(report.join('\n'));
  await browser.close();
})();
