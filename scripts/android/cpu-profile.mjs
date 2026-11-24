// Hồ sơ CPU Dart của bản profile trên máy thật qua VM service (cùng dữ liệu tab CPU Profiler của DevTools) - QA-11.
// Chạy bằng node.exe (adb.exe forward chỉ mở localhost của Windows):
//   node.exe scripts/android/cpu-profile.mjs ws://127.0.0.1:<cổng>/<token>=/ws <số giây> [số dòng]
// In: tổng mẫu, rồi các hàm theo "tự thân" (self) và "bao gồm" (inclusive) - phần trăm trên mọi mẫu của isolate UI.
const [url, secs = '10', top = '30'] = process.argv.slice(2);
const ws = new WebSocket(url);
let id = 0;
const waiting = new Map();
const call = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const n = String(++id);
    waiting.set(n, { resolve, reject });
    ws.send(JSON.stringify({ jsonrpc: '2.0', id: n, method, params }));
  });
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  const w = waiting.get(m.id);
  if (!w) return;
  waiting.delete(m.id);
  m.error ? w.reject(new Error(JSON.stringify(m.error))) : w.resolve(m.result);
};
ws.onopen = async () => {
  try {
    const vm = await call('getVM');
    const iso = vm.isolates.find((i) => i.name === 'main') ?? vm.isolates[0];
    // Bản profile tắt bộ lấy mẫu tới khi có client bật (DevTools bật khi mở tab CPU Profiler).
    await call('setFlag', { name: 'profiler', value: 'true' });
    await new Promise((r) => setTimeout(r, 1000));
    await call('clearCpuSamples', { isolateId: iso.id });
    const t0 = (await call('getVMTimelineMicros')).timestamp;
    await new Promise((r) => setTimeout(r, Number(secs) * 1000));
    const t1 = (await call('getVMTimelineMicros')).timestamp;
    const s = await call('getCpuSamples', { isolateId: iso.id, timeOriginMicros: t0, timeExtentMicros: t1 - t0 });
    const name = (f) => {
      const fn = f.function ?? {};
      const owner = fn.owner?.name ? `${fn.owner.name}.` : '';
      const lib = fn.location?.script?.uri ?? fn.owner?.library?.uri ?? fn.resolvedUrl ?? '';
      return `${owner}${fn.name ?? f.kind} ${lib.replace(/^.*\/(lib|src)\//, '')}`.trim();
    };
    const self = new Map();
    const incl = new Map();
    for (const smp of s.samples) {
      const st = smp.stack ?? [];
      if (st.length) self.set(st[0], (self.get(st[0]) ?? 0) + 1);
      for (const fi of new Set(st)) incl.set(fi, (incl.get(fi) ?? 0) + 1);
    }
    const n = s.samples.length;
    const show = (title, m) => {
      console.log(`\n## ${title}`);
      [...m.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, Number(top))
        .forEach(([fi, c]) => console.log(`${((100 * c) / n).toFixed(1).padStart(5)}%  ${c}\t${name(s.functions[fi])}`));
    };
    console.log(`isolate ${iso.name}, ${secs} s, ${n} mẫu (chu kỳ ${s.samplePeriod} µs)`);
    show('Tự thân', self);
    show('Bao gồm', incl);
  } catch (e) {
    console.error(e.message);
    process.exitCode = 1;
  }
  ws.close();
};
ws.onerror = (e) => {
  console.error('ws lỗi', e.message ?? e);
  process.exit(1);
};
