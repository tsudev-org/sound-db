// Hoạ tiết chữ ký `song-am` (sóng âm) của Sound Db - tsudev-standards v5.0.0 DESIGN_SYSTEM 1.2.4: TĨNH, vẽ bằng
// accent/glow của sản phẩm, độ phủ <= 15%. Dùng chung cho hero website (src/views/TrangChu.astro) và og-image
// (scripts/brand-assets.mjs) để hai nơi cùng một hình. Trả về danh sách thuộc tính `d` của <path> (toạ độ SVG).

/**
 * @param {number} w bề rộng vùng vẽ
 * @param {number} h bề cao vùng vẽ
 * @param {{ lines?: number, step?: number }} [opt]
 * @returns {{ d: string, opacity: number }[]}
 */
export function songAm(w, h, opt = {}) {
  const lines = opt.lines ?? 7;
  const step = opt.step ?? 6;
  const mid = h / 2;
  const out = [];
  for (let i = 0; i < lines; i++) {
    // Mỗi đường một tần số + pha; bao hình chuông (to ở giữa, tắt dần hai mép) như dạng sóng của một tiếng gõ.
    const k = (i - (lines - 1) / 2) / ((lines - 1) / 2 || 1); // -1..1
    const amp = h * 0.36 * (1 - 0.55 * Math.abs(k));
    const f1 = 2.2 + i * 0.9;
    const f2 = 5.3 + i * 1.7;
    const ph = i * 0.85;
    let d = '';
    for (let x = 0; x <= w; x += step) {
      const t = x / w;
      const env = Math.exp(-((t - 0.5) ** 2) / 0.06);
      const y = mid + amp * env * (0.75 * Math.sin(2 * Math.PI * f1 * t + ph) + 0.25 * Math.sin(2 * Math.PI * f2 * t - ph));
      d += `${x === 0 ? 'M' : 'L'}${x.toFixed(1)} ${y.toFixed(1)}`;
    }
    out.push({ d, opacity: Number((0.35 + 0.65 * (1 - Math.abs(k))).toFixed(2)) });
  }
  return out;
}
