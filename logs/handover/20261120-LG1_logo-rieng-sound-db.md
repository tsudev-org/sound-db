# 20261120-LG1 - sound-db: logo riêng Sound Db cho website, app và mọi tệp xuất

- **Người lập**: phiên `tsuswico-57`, 20/11/2026, theo yêu cầu trực tiếp của chủ dự án.
- **Người làm**: phiên sound-db. **Trạng thái**: ĐÓNG (20/11/2026, `sound-db-28`) - còn bước 6 sau deploy.
- **Chuẩn**: `.standards/docs/BRAND_ASSETS.md` mục 12, **15**, 15.5 (khối nhà làm giữ logo tsudev), `ECOSYSTEM_IDENTITY.md`.
- **Phiếu liên quan**: tsudev `20261120-LG1` (danh bạ tsudev.com/apps - mục 2 bước 6).

## 1. Ảnh gốc chủ dự án giao

- Tệp: `~/projects/sound-db/logo-sound-db.png` (đang ở GỐC repo, chưa track) - PNG 1024x1024, cột sóng âm xanh
  dương/xanh lá + nửa mặt đồng hồ trên **nền navy đặc** (`~#0f1a2e`).
- SHA-256: `32c1ae431ca6878e8059d9459cf84d5c317927ecadd741b0c2c7b4a297bd1955`
- Duyệt: chủ dự án giao 20/11/2026 - đủ điều kiện mục 15. Ghi vào tài liệu repo (dòng "chưa có logo riêng" ⇒ đổi).

## ⚠️ 2. Phải xử lý trước khi dùng: dấu ✦ của công cụ tạo ảnh

Góc **phải dưới** ảnh có dấu sao bốn cánh ✦ màu xám (khoảng x 880-930, y 880-930 px) - dấu nhận diện của công cụ tạo
ảnh, KHÔNG thuộc logo. Chế độ `tile` cắt vuông nguyên ảnh nên dấu này sẽ lọt vào mọi icon/favicon. Chọn một:

- (khuyên) hỏi chủ dự án bản gốc sạch; hoặc
- tô vùng đó bằng màu nền **một lần** trên ảnh gốc (ghi rõ thao tác + SHA mới trong tài liệu brand); hoặc
- thêm bước cắt vùng giữa (vd vuông 200-824 px, logo nằm trong ~260-760 x 295-725) vào dây chuyền - ảnh gốc khi
  đó < 1024 ⇒ bản 1024 là phóng to, ghi nợ theo mục 15.

`MUST NOT` phát hành icon còn dấu ✦.

## 3. Việc phải làm

1. Chuyển ảnh (đã xử lý mục 2) vào `assets/brand/source/logo-sound-db.png`; ghi SHA-256.
2. `assets/brand/brand.json`: `source` ⇒ tệp mới, `mode: "tile"` (logo trên nền đặc - GIỮ nền, bo góc),
   `solidBg` = màu nền navy của ảnh; sửa `_ghi_chu`, chữ OG.
3. `node apps/web/scripts/brand-assets.mjs` ⇒ đủ bộ mục 12; CI `--check` xanh.
4. **Website `apps/web`**: header = logo Sound Db + tên; footer giữ khối nhà làm logo tsudev hiện hành.
5. **App `apps/app`**: icon launcher mọi nền tảng (Android/Apple/Windows/Linux) + bản web (favicon, manifest), logo
   trong giao diện, sinh từ cùng ảnh gốc. Mọi tệp app xuất ra (bản ghi đo, báo cáo, ảnh chia sẻ nếu có): logo + favicon
   sản phẩm nhúng thẳng, chân trang nhà làm tsudev. Mẫu nhúng ảnh vào báo cáo: tsuswico PR
   [#59](https://github.com/tsudev-org/tsuswico/pull/59).
6. Sau khi deploy: báo phiên `tsudev` URL `https://sounddb.tsudev.com/brand/logo-sound-db.png` (mục 15.6).
7. Kiểm: axe sáng/tối, ảnh chụp, `--check`, chạy thử app.

## 4. Kết quả

- 20/11/2026 - `sound-db-28`:
  - Mục 2: chọn phương án 3 (cắt vùng giữa) nhưng làm trong dây chuyền, KHÔNG sửa pixel ảnh gốc: `brand.json`
    `crop = {left 159, top 160, size 704}` (logo nằm 263-759 x 296-727; dấu ✦ ở 880-930 nằm ngoài). Bản 1024 là phóng to
    từ 704 ⇒ ghi nợ ở AGENTS.md B.4. Ảnh gốc giữ nguyên SHA `32c1ae43…1955` tại `assets/brand/source/logo-sound-db.png`;
    bỏ `source/logo-tsudev.png`.
  - `solidBg` `#0e192d` (lấy mẫu nền), OG glow `#0e3a4a`, chữ miền `#22c55e`. Dây chuyền sinh 58 tệp, `--check` khớp.
  - Web: header dùng `brand/logo-sound-db-*` (đã là logo mới), chân trang giữ khối nhà làm `brand/logo-tsudev-*`.
  - App: icon Android mipmap, iOS/macOS AppIcon, Windows `app_icon.ico`, Linux `.desktop` (`assets/brand/icon-512.png`)
    sinh cùng nguồn; logo trong giao diện ở Cài đặt → Giới thiệu. Tệp xuất của app là CSV/JSON dữ liệu đo (không có chỗ
    nhúng ảnh) ⇒ không đổi định dạng. flutter analyze sạch, flutter test 15/15; web 17/17, build + check-dist đạt.
  - Bước 6 (báo phiên tsudev URL logo) làm sau khi deploy production.
