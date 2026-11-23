#!/usr/bin/env node
// Sinh token giao diện cho app Flutter (Dart) và website (CSS) từ BA nguồn (tsudev-standards v5.0.0, DESIGN_SYSTEM 1.2):
//   .standards/tokens/design-tokens.json     (lớp nền chung, chỉ-đọc)
//   .standards/tokens/products/sounddb.json  (lớp bản sắc Sound Db: vai trò nhấn + bo góc, chỉ-đọc)
//   tokens/extensions.sound-db.json          (riêng repo: màu biểu đồ đo, thang mức dB, ngưỡng đồng hồ)
// Website KHÔNG lấy bảng màu ở đây mà nạp thẳng .standards/tokens/tokens.css + products.css; tệp CSS sinh ra chỉ
// thêm biến biểu đồ (--chart-*, --spectrogram-*, --zone-*).
// Dùng: node scripts/build-tokens.mjs          # ghi tệp
//       node scripts/build-tokens.mjs --check  # CI: đỏ nếu tệp sinh ra lệch nguồn hoặc tương phản không đạt
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const base = JSON.parse(readFileSync(resolve(root, '.standards/tokens/design-tokens.json'), 'utf8'));
const product = JSON.parse(readFileSync(resolve(root, '.standards/tokens/products/sounddb.json'), 'utf8'));
const ext = JSON.parse(readFileSync(resolve(root, 'tokens/extensions.sound-db.json'), 'utf8'));
const check = process.argv.includes('--check');

const modes = ['light', 'dark'];
// Bộ bo góc `chuan` (DESIGN_SYSTEM 1.2.3) = giá trị nền; nút dùng radius-control.
const SHAPES = { sac: [2, 3, 4, 3], chuan: [4, 6, 8, 6], mem: [6, 10, 14, 10], tron: [8, 14, 20, 999] };
const [rs, rm, rl, rc] = SHAPES[product.shape];
const radius = { ...base.radius, sm: `${rs}px`, md: `${rm}px`, lg: `${rl}px`, control: `${rc}px` };
const palette = {};
for (const mode of modes) {
  palette[mode] = { ...base.color[mode], ...product.colors[mode] };
  // Đường phổ/biểu đồ dùng màu nhấn của sản phẩm; thang mức dB (xanh-vàng-đỏ) là trực quan hoá dữ liệu, giữ nguyên.
  const chart = { line: product.colors[mode].primary, fill: product.colors[mode].glow, ...ext.chart[mode] };
  for (const [k, v] of Object.entries(chart)) palette[mode][`chart-${k}`] = v;
}

// ---- Tương phản WCAG ----
function rgb(hex) {
  const m = /^#([0-9a-f]{6})$/i.exec(hex);
  if (!m) return null;
  const n = parseInt(m[1], 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function lum([r, g, b]) {
  const f = (c) => {
    c /= 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}
function ratio(a, b) {
  const [x, y] = [lum(rgb(a)), lum(rgb(b))].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
}
const problems = [];
for (const mode of modes) {
  const p = palette[mode];
  const pairs = [
    ['text-primary', 'bg-base', 4.5], ['text-secondary', 'bg-surface', 4.5], ['text-muted', 'bg-surface', 4.5],
    ['text-link', 'bg-base', 4.5], ['on-primary', 'primary', 4.5], ['on-primary', 'primary-hover', 4.5],
    ['on-primary', 'primary-active', 4.5], ['accent', 'bg-surface', 4.5], ['border-control', 'bg-surface', 3],
    ['focus-ring', 'bg-base', 3],
    ['chart-line', 'bg-surface', 3], ['chart-peak', 'bg-surface', 3], ['chart-axis', 'bg-surface', 4.5],
    ['chart-level-safe', 'bg-surface', 3], ['chart-level-caution', 'bg-surface', 3], ['chart-level-danger', 'bg-surface', 3],
  ];
  for (const [fg, bg, min] of pairs) {
    const r = ratio(p[fg], p[bg]);
    if (r < min) problems.push(`${mode}: ${fg} trên ${bg} = ${r.toFixed(2)} < ${min}`);
  }
}

// ---- Dart ----
function dartColor(value) {
  const hex = rgb(value);
  if (hex) return `Color(0xFF${value.slice(1).toUpperCase()})`;
  const m = /rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)/.exec(value);
  if (!m) throw new Error(`không hiểu màu ${value}`);
  const a = Math.round(parseFloat(m[4]) * 255);
  const h = (n) => Number(n).toString(16).padStart(2, '0').toUpperCase();
  return `Color(0x${h(a)}${h(m[1])}${h(m[2])}${h(m[3])})`;
}
const camel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
const keys = Object.keys(palette.dark).filter((k) => k in palette.light);
let dart = `// TỆP SINH TỰ ĐỘNG bởi scripts/build-tokens.mjs - KHÔNG SỬA TAY.
// Nguồn: .standards/tokens/design-tokens.json + .standards/tokens/products/sounddb.json + tokens/extensions.sound-db.json
// ignore_for_file: public_member_api_docs

import 'dart:ui' show Color;

class SdbPalette {
  const SdbPalette({
${keys.map((k) => `    required this.${camel(k)},`).join('\n')}
  });

${keys.map((k) => `  final Color ${camel(k)};`).join('\n')}

${modes
  .map(
    (mode) => `  static const ${mode} = SdbPalette(
${keys.map((k) => `    ${camel(k)}: ${dartColor(palette[mode][k])},`).join('\n')}
  );`,
  )
  .join('\n\n')}
}

const List<Color> spectrogramStops = [
${ext.chart.spectrogram.map((c) => `  ${dartColor(c)},`).join('\n')}
];

class SdbRadius {
${Object.entries(radius)
  .map(([k, v]) => `  static const double ${k === 'none' ? 'none' : k} = ${parseFloat(v)};`)
  .join('\n')}
}

class SdbSpacing {
${Object.entries(base.spacing)
  .map(([k, v]) => `  static const double s${k} = ${parseFloat(v) * (String(v).endsWith('rem') ? 16 : 1)};`)
  .join('\n')}
}

class SdbMeterZones {
  static const double caution = ${ext['meter-zones'].caution};
  static const double danger = ${ext['meter-zones'].danger};
}
`;

// ---- CSS (chỉ biến biểu đồ; bảng màu/bo góc/font do .standards/tokens/{tokens,products}.css cấp) ----
const chartVars = (mode) =>
  Object.entries(palette[mode]).filter(([k]) => k.startsWith('chart-')).map(([k, v]) => `  --${k}: ${v};`).join('\n');
const css = `/* TỆP SINH TỰ ĐỘNG bởi scripts/build-tokens.mjs - KHÔNG SỬA TAY.
   Nguồn: tokens/extensions.sound-db.json + màu nhấn .standards/tokens/products/sounddb.json.
   Nạp SAU .standards/tokens/tokens.css + products.css; data-theme do public/theme.js đặt trước khi vẽ. */
:root,
[data-theme='light'] {
${chartVars('light')}
}

[data-theme='dark'] {
${chartVars('dark')}
}

:root {
${ext.chart.spectrogram.map((c, i) => `  --spectrogram-${i}: ${c};`).join('\n')}
  --zone-caution: ${ext['meter-zones'].caution};
  --zone-danger: ${ext['meter-zones'].danger};
}
`;

const outputs = [
  [resolve(root, 'apps/app/lib/theme/tokens.g.dart'), dart],
  [resolve(root, 'apps/web/src/styles/tokens.css'), css],
];
let drift = false;
for (const [file, content] of outputs) {
  if (check) {
    if (!existsSync(file) || readFileSync(file, 'utf8') !== content) {
      console.error(`LỆCH: ${file} không khớp nguồn - chạy node scripts/build-tokens.mjs`);
      drift = true;
    }
  } else {
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, content);
    console.log(`đã ghi ${file.replace(root + '/', '')}`);
  }
}
for (const p of problems) console.error(`TƯƠNG PHẢN: ${p}`);
if (problems.length || drift) process.exit(1);
console.log('Token: đạt (tương phản WCAG + khớp nguồn).');
