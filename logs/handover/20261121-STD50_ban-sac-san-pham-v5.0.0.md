# PHIẾU YÊU CẦU - Bản sắc riêng của Sound Db (tsudev-standards v5.0.0)

- **Mã phiếu**: 20261121-STD50
- **Từ**: phiên tsudev-standards, 21/11/2026 - **Đến**: phiên kế tiếp của `sound-db`
- **Trạng thái**: ĐÓNG (23/11/2026, PR #34, #35)
- **Nguồn**: https://github.com/tsudev-org/tsudev-standards/releases/tag/v5.0.0 - `docs/DESIGN_SYSTEM.md` mục 1.2,
  CHANGELOG 5.0.0 "Hướng dẫn nâng cấp"
- **Bối cảnh**: chủ dự án muốn mỗi sản phẩm có đặc trưng nổi bật riêng (màu, giao diện, bố cục). Trước v5.0.0, 9/11
  sản phẩm dùng cùng một màu xanh. Từ v5.0.0: nền/chữ/trạng thái/tiếp cận là chung; màu nhấn, bố cục, bo góc, hoạ
  tiết, font tiêu đề là riêng, khai ở `.standards/tokens/products/sounddb.json` - KHÔNG tự khai lại tại repo này.

## Bản sắc đã chốt cho `sound-db`

| Trường | Giá trị |
| --- | --- |
| `data-product` | `sounddb` |
| Màu chính Tối / Sáng | `#7DB530` / `#4C7601` (hue OKLCH 130; lý do: xanh lục của logo đẩy về vàng chanh của đồng hồ VU, tách khỏi Quly Thu Chi) |
| Bố cục `layout` | `do-luong` - một mặt đồng hồ/biểu đồ lớn ở trung tâm, số liệu phụ xếp quanh |
| Bo góc `shape` | `chuan` - 4/6/8px, nút 6px |
| Hoạ tiết `motif` | `song-am` (tĩnh, ở hero + `og-image`, phủ ≤ 15%) |
| Font tiêu đề | Space Grotesk (tự host woff2 bộ `vietnamese`, tối đa 2 độ đậm) |

Muốn đổi bất kỳ giá trị nào: PR vào tsudev-standards (sửa `hue`/`layout`... + chạy `gen-product-palette.mjs`), cổng
kiểm chống trùng phải xanh. KHÔNG ghi đè tại repo này.

## Việc cần làm - chia hai PR, mỗi PR một phiên

**PR 1 - màu + hình** (`feat(ui): bản sắc sounddb theo tsudev-standards v5.0.0`):
1. Sync `.standards/` lên v5.0.0 (bước `curl` sync-standards.sh trước, theo `docs/SYNC.md`).
2. Web: nạp `.standards/tokens/tokens.css` rồi `.standards/tokens/products.css`; `<html data-product="sounddb">` (cạnh
   `data-theme`). Desktop/di động: gộp đè `products/sounddb.json` lên `color.light`/`color.dark` lúc build.
3. Xoá bảng màu tự khai (`palette.css`, `extensions.*.json`, dải `--color-*` riêng) và mã màu cứng còn sót.
4. Giá trị đã lưu `warm` đọc thành `light` (khối `warm` đã gỡ khỏi token).
5. Nút dùng `var(--radius-control)`; h1-h3 và số liệu lớn dùng `var(--font-display)`.
6. Ảnh chụp trước/sau, Sáng + Tối, đính vào PR. Cổng kiểm + test xanh.

**PR 2 - bố cục** (`feat(ui): bố cục do-luong + hoạ tiết song-am`):
1. Dựng phần THÂN trang chủ website / màn hình đầu app theo `do-luong`; header, khu tài khoản, chân trang, bộ chọn
   giao diện giữ theo `ECOSYSTEM_IDENTITY.md` mục 4.
2. Hoạ tiết `song-am` tĩnh ở hero, vẽ bằng `accent`/`glow`; sinh lại `og-image.png` cùng hoạ tiết.
3. Ảnh chụp trước/sau, Sáng + Tối.

## Việc riêng của repo này

- Màu vàng chanh của đồng hồ VU (hue 130). Thang màu mức dB (xanh-vàng-đỏ) là trực quan hoá dữ liệu, KHÔNG thay bằng `primary`.

## Kết quả xử lý

- 
- 23/11/2026 (agent-sound): **XONG cả hai PR**, đã deploy production (sound.tsudev.com có `data-product="sounddb"`).
  - PR #34 `feat(ui): bản sắc sounddb theo tsudev-standards v5.0.0`: sync `.standards` v5.0.0; web nạp
    `.standards/tokens/tokens.css` + `products.css`, `data-product`, `data-platform="web"`; Space Grotesk tự host
    (vietnamese + latin, 500/700); `build-tokens.mjs` gộp lớp nền + `products/sounddb.json`, extensions chỉ còn biểu
    đồ; nút `--radius-control` (web) / `SdbRadius.control` (app). Ảnh trước/sau: `docs/ui/ban-sac-v5/`.
  - PR #35 `feat(ui): bố cục do-luong + hoạ tiết song-am`: trang chủ mặt đồng hồ trung tâm + 4 số liệu quanh;
    `src/lib/song-am.mjs` dùng chung hero + og-image; app màn Đo mức dùng `LevelDial`.
  - Lệch còn lại: app Flutter chưa dùng Space Grotesk (chỉ web) - chuẩn chỉ đòi gộp màu ở app; thêm font vào app khi
    có lý do (tăng cỡ gói). Phát hành trong bản 26.11.2301.
- **Trạng thái: ĐÓNG.**
