// Công cụ rà giao diện UI2 (phiếu logs/handover/20261125-UI2_*); Playwright mượn của repo tsudev (đặt PLAYWRIGHT=... để đổi).
// UI2: quay khung hình tải lạnh + đo đổi font. Dùng: node film.cjs <url> <nhãn> [rộng] [light|dark]
const path = require('path');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT || path.join(process.env.HOME, 'projects/tsudev/node_modules/playwright'));

(async () => {
  const [url, label, width = '1366', scheme = 'light'] = process.argv.slice(2);
  const out = path.join(process.env.OUT || path.join(__dirname, '../../logs/qa/ui2'), label);
  fs.rmSync(out, { recursive: true, force: true });
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const w = Number(width);
  const ctx = await browser.newContext({ viewport: { width: w, height: w < 500 ? 740 : 800 }, colorScheme: scheme, locale: 'vi-VN' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') errors.push(`console.${m.type()}: ${m.text()}`); });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  page.on('response', (r) => { if (r.status() >= 400) errors.push(`HTTP ${r.status()} ${r.url()}`); });
  await page.addInitScript(() => {
    window.__shifts = [];
    new PerformanceObserver((l) => { for (const e of l.getEntries()) if (!e.hadRecentInput) window.__shifts.push([Math.round(e.startTime), +e.value.toFixed(4)]); }).observe({ type: 'layout-shift', buffered: true });
    window.__widths = [];
    const probe = () => {
      const h = document.querySelector('h1');
      if (h) window.__widths.push([Math.round(performance.now()), Math.round(h.getBoundingClientRect().width * 10) / 10, Math.round(h.getBoundingClientRect().height)]);
      if (performance.now() < 6000) requestAnimationFrame(probe);
    };
    requestAnimationFrame(probe);
  });
  const cdp = await ctx.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 150, downloadThroughput: 4e6 / 8, uploadThroughput: 1e6 / 8 });
  const frames = [];
  let t0 = 0;
  cdp.on('Page.screencastFrame', async (f) => {
    frames.push({ t: Math.round(Date.now() - t0), data: f.data });
    await cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {});
  });
  await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 60, everyNthFrame: 1 });
  t0 = Date.now();
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(3500);
  await cdp.send('Page.stopScreencast');
  const shifts = await page.evaluate(() => window.__shifts);
  const widths = await page.evaluate(() => window.__widths);
  const fonts = await page.evaluate(() => [...document.fonts].filter((f) => f.status === 'loaded').map((f) => `${f.family} ${f.weight}`));
  const lcp = await page.evaluate(() => new Promise((r) => new PerformanceObserver((l) => { const e = l.getEntries(); r(Math.round(e[e.length - 1].startTime)); }).observe({ type: 'largest-contentful-paint', buffered: true })));
  // Bề rộng h1 thay đổi = đổi font (dòng chữ "nhúng").
  const distinct = [];
  for (const [t, wd, ht] of widths) if (!distinct.length || distinct[distinct.length - 1][1] !== wd || distinct[distinct.length - 1][2] !== ht) distinct.push([t, wd, ht]);
  // Bảng khung: chọn ~12 khung trong 0-3 s.
  const pick = [];
  for (const target of [0, 150, 300, 450, 600, 800, 1000, 1300, 1600, 2000, 2500, 3200]) {
    const f = frames.find((x) => x.t >= target) || frames[frames.length - 1];
    if (f && !pick.includes(f)) pick.push(f);
  }
  const sheet = await ctx.newPage();
  const cell = w < 500 ? 180 : 300;
  await sheet.setViewportSize({ width: cell * 4 + 40, height: 200 });
  await sheet.setContent(`<body style="margin:0;background:#888;display:grid;grid-template-columns:repeat(4,${cell}px);gap:8px;padding:8px;font:12px sans-serif">${pick
    .map((f) => `<div><div>${f.t} ms</div><img style="width:${cell}px;border:1px solid #000" src="data:image/jpeg;base64,${f.data}"></div>`)
    .join('')}</body>`);
  await sheet.screenshot({ path: path.join(out, 'sheet.png'), fullPage: true });
  console.log(JSON.stringify({ url, label, width: w, scheme, frames: frames.length, lcp, shifts, h1Widths: distinct, fontsLoaded: fonts.length, errors: errors.slice(0, 15) }, null, 1));
  await browser.close();
})();
