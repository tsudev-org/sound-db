// Ngân sách tốc độ web (tsudev-standards v5.1.0 LANGUAGE_SELECTION.md mục 5.1): JS tải ban đầu mỗi trang <= 170 KB gzip.
// Đếm script nội tuyến + script `src` cùng nguồn trong dist/ (module tải động như WASM của /do/ không tính là ban đầu).
// LCP/CLS cần trình duyệt đo thật - chưa có trong CI (phiếu 20261124-QR1, STD-SYNC).
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join, relative } from 'node:path';
import { gzipSync } from 'node:zlib';

const DIST = new URL('../dist/', import.meta.url).pathname;
const LIMIT_KB = 170;

const pages = [];
(function walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p);
    else if (p.endsWith('.html')) pages.push(p);
  }
})(DIST);

let failed = false;
let worst = { page: '', kb: 0 };
for (const page of pages) {
  const html = readFileSync(page, 'utf8');
  const inline = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map((m) => m[1]).join('');
  let bytes = gzipSync(inline).length;
  for (const [, src] of html.matchAll(/<script[^>]*\bsrc="(\/[^"]+)"/g)) {
    const file = join(DIST, src.split('?')[0]);
    if (existsSync(file)) bytes += gzipSync(readFileSync(file)).length;
  }
  const kb = bytes / 1024;
  if (kb > worst.kb) worst = { page: relative(DIST, page), kb };
  if (kb > LIMIT_KB) {
    console.error(`VƯỢT NGÂN SÁCH: ${relative(DIST, page)} - JS ban đầu ${kb.toFixed(1)} KB gzip > ${LIMIT_KB} KB`);
    failed = true;
  }
}
if (pages.length === 0) {
  console.error('Không thấy trang nào trong dist/ - chạy build trước.');
  process.exit(1);
}
console.log(`Ngân sách JS: ${pages.length} trang, lớn nhất ${worst.page} ${worst.kb.toFixed(1)} KB gzip (ngưỡng ${LIMIT_KB} KB).`);
process.exit(failed ? 1 : 0);
