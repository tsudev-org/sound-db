# PHIẾU ĐỀ XUẤT - Logo riêng cho Sound Db (agent-sound → chủ dự án)

- **Mã phiếu**: 20261117-04
- **Từ**: agent-sound - **Đến**: chủ dự án (OWNER) duyệt theo `BRAND_ASSETS.md` mục 15
- **Thời điểm**: 20:35 17/11/2026
- **Trạng thái**: MỞ - chờ chủ dự án chọn phương án (hoặc từ chối, giữ logo tsudev)
- **Nhánh git**: không - chỉ đề xuất; `assets/brand/` CHƯA đổi

## 1. Ba phương án (SVG 1024×1024, ô nền đặc bo góc như chế độ `tile` hiện tại)

Tệp nằm trong `logs/handover/20261117-04_logo/`. Đã xuất thử 256/64/32/16 px: cả ba vẫn nhận ra ở cỡ favicon 16 px.

| Mã | Tệp | Ý tưởng | Ghi chú |
| --- | --- | --- | --- |
| A | `A-cot-muc.svg` | Cột mức âm (như đồng hồ VU), đỉnh vàng là mức đỉnh | Gần chức năng phổ đồ; rõ nhất ở 16 px |
| B | `B-dong-ho.svg` | Đồng hồ kim đo dB, cung xanh → cam | Thể hiện "máy đo mức âm" trực tiếp nhất |
| C | `C-song-am.svg` | Dạng sóng trong vòng đo hở | Mềm, gần "âm thanh" hơn "đo lường" |

Màu bám token hiện có: nền `#0b2233 → #03070c`, nhấn `#38bdf8`/`#22d3ee` (`brand.json` `ogAccent`).

## 2. Việc của chủ dự án (👤)

- [ ] Chọn A, B hoặc C (có thể kèm chỉnh màu/nét), hoặc ghi "giữ logo tsudev".

## 3. Khi đã duyệt (agent làm, một PR)

1. Chép SVG được chọn vào `assets/brand/source/logo-sound-db.svg`, ghi SHA-256 trong `assets/brand/brand.json`
   (`source`, `_ghi_chu`); giữ `mode: tile`.
2. `node apps/web/scripts/brand-assets.mjs` sinh lại favicon/PWA/og-image/icon desktop; sinh icon Android/iOS.
3. CI `--check` xanh; khối "nhà làm" + chân trang vẫn dùng logo tsudev (mục 15.5).
4. Báo phiên repo `tsudev` URL logo mới cho danh bạ tsudev.com/apps (mục 15.6).
5. Xóa dòng "Logo" ở `AGENTS.md` B.4.
