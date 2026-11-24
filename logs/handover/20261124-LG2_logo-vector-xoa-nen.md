# PHIẾU YÊU CẦU LG2 - Logo vector xoá nền: nhận SVG làm ảnh gốc, favicon/logo website không còn ô nền tối

- **Mã phiếu**: 20261124-LG2 - **Từ**: phiên `projects-71` (repo tsudev), 24/11/2026 - **Trạng thái**: MỞ
- **Căn cứ**: yêu cầu chủ dự án 24/11/2026 ("logo có màu nền làm tối hình ảnh... thiếu chuyên nghiệp"; đổi PNG sang định
  dạng hiện đại sắc nét mọi thiết bị); tsudev-standards `BRAND_ASSETS.md` mục 15 (bản 15.4 mới: xoá nền + hai bản).
- **Nguồn**: tsudev `packages/brand/build-vector-marks.js` sinh từ CHÍNH ảnh gốc `assets/brand/source/` của repo này
  (SHA-256 khớp), đang phục vụ ở `https://tsudev.com/eco/sounddb.svg`, `sounddb-light.svg`, `sounddb-adaptive.svg`.

## Việc

1. Tải ba tệp trên vào `assets/brand/source/` (`mark.svg`, `mark-light.svg`, `mark-adaptive.svg`), ghi SHA-256 vào
   `brand.json` (`_ghi_chu`) - ảnh PNG cũ GIỮ làm gốc của gốc (đổi logo: thay PNG ⇒ chạy lại dây chuyền tsudev ⇒ tải lại).
2. Sửa `apps/web/scripts/brand-assets.mjs` + `brand.json`: chế độ mới `svg` - mọi bản WEB sinh từ SVG (sharp `density` đủ lớn, không phóng to PNG):
   - `favicon.svg` = `mark-adaptive.svg` (tự đổi theo `prefers-color-scheme`) + `<link rel="icon" type="image/svg+xml">`
     đặt TRƯỚC `favicon.ico`; `favicon.ico` 7 lớp + `favicon-96x96.png` vẫn sinh (trình duyệt cũ), nền trong suốt;
   - logo header/hero: hai `<img>` (bản Tối/Sáng) đổi theo chủ đề của site, hoặc `<picture>` với
     `media="(prefers-color-scheme: light)"` nếu site không có nút chủ đề; bỏ ô bo góc nền tối;
   - `apple-touch-icon` (180, nền đặc bắt buộc), PWA `maskable`, og-image: nền đặc `solidBg` + `mark.svg` - vẫn là ô
     (quy ước nền tảng), nhưng sinh từ SVG nên sắc hơn;
   - icon ứng dụng hệ điều hành (`.ico`, Android launcher, `.icns`, PNG Linux, khay): GIỮ ô nền đặc, sinh từ SVG.
3. Cổng `--check` trong CI phủ các tệp mới; xoá tệp đã sinh không còn dùng (Clean Codebase - `PROJECT_STRUCTURE` 3.1).
4. Nghiệm thu: ảnh chụp sound.tsudev.com ở Sáng + Tối (header, tab trình duyệt), favicon trên Chrome/Edge/Firefox; deploy website;
   báo phiên tsudev nếu repo tự phục vụ `/brand/mark*.svg` để `build-vector-marks.js` đổi nguồn sang URL đó.

## Kết quả xử lý

- 24/11/2026 - projects-71: mở phiếu; tsudev.com/apps đã dùng SVG xoá nền (PR tsudev).
- 24/11/2026 - sound-db-c9: làm xong ở repo (PR kế): 3 SVG vào `assets/brand/source/mark*.svg` (lấy từ repo tsudev nhánh
  `feat/logo-vector-xoa-nen` - URL tsudev.com/eco/* còn 404), SHA-256 ghi `brand.json`; `brand-assets.mjs` chế độ `vector`:
  web logo trong suốt hai bản (header đổi theo `data-theme`), `favicon.svg` = adaptive đặt trước `favicon.ico` (khai
  `sizes="32x32"`), favicon/PWA "any" trong suốt; icon hệ điều hành + maskable + apple-touch + OG vẫn ô nền đặc nhưng
  dựng từ SVG (hết nợ AGENTS B.4 "icon 1024 phóng to từ 704"). `--check` phủ 69 tệp; `check-dist` đòi `favicon.svg`.
  Kèm BRAND_ASSETS 4.1.0: dấu hiệu TsuDEV trước liên kết tsudev.com (chân trang, nút Pro/Ủng hộ web; Cài đặt + màn Pro app).
