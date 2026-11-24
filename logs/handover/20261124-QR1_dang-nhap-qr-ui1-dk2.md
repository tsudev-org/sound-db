# PHIẾU YÊU CẦU QR1 + UI1 + DK2 - sound-db

- **Mã phiếu**: 20261124-QR1 (bản sao cho repo) - **Từ**: điều phối `projects-71`, 24/11/2026 - **Trạng thái**: MỞ
- **Phiếu gốc** (đọc phần liên quan): `~/projects/logs/handover/20261124-QR1_dang-nhap-qr-giao-dien-thong-nhat-toan-he.md`,
  `20261124-UI1_bieu-tuong-kho-thay-toan-he.md`, `20261124-DK2_dang-ky-bct-tin-nhiem-mang-chong-lua-dao.md`.
- **Chuẩn**: tsudev-standards **v5.1.0** - `CROSS_DEVICE_LOGIN.md`, `AUTH_AND_ACCOUNT.md` 3.0/13.2/13.4,
  `DESIGN_SYSTEM.md` 1 (biểu tượng trên viên chỉ báo), `LANGUAGE_SELECTION.md` 5.1, `PROJECT_STRUCTURE.md` 3.1,
  `BRAND_ASSETS.md` 12.3.
- **Hạng / loại**: B - Flutter + Rust + web

## Việc của repo này

1. **QR3** như qulythuchi (đăng nhập qua máy chủ Sound Db theo ADR-0003 - đối chiếu với `CROSS_DEVICE_LOGIN`: thiết bị mới vẫn nhận authorization code của IdP rồi đi tiếp luồng ADR-0003). **UI1**: lỗi đã xác nhận ở `apps/app/lib/theme/app_theme.dart` (Đo mức/Phân tích/Công cụ/Lịch sử/Cài đặt) + rail thiếu `selectedIconTheme`. DK2: footer sound.tsudev.com nhận nhãn sau duyệt
2. **STD-SYNC** trong PR kế tiếp (không PR riêng): sync v5.1.0, bật cổng Clean Codebase (mã chết/phụ thuộc thừa) và
   ngân sách tốc độ; liên kết về tsudev.com kèm dấu hiệu TsuDEV + favicon đủ bộ.
3. Rà **UI1** cả Sáng/Tối: biểu tượng trên nền thật ở mọi trạng thái ≥ 3:1, thêm test chặn tái phát (nếu có giao diện).

Repo có phiên riêng ⇒ phiên đó làm; ghi kết quả một dòng dưới đây + dòng tương ứng ở phiếu gốc; `akb` theo chuẩn.

## Kết quả xử lý

- 24/11/2026 - projects-71: mở phiếu.
- 24/11/2026 - sound-db-c9: **UI1 sửa** (`app_theme.dart`): ColorScheme khai đủ `primary/secondary/tertiaryContainer` +
  `on*Container` (token), NavigationBar `indicatorColor` = `primary` 14 % + `iconTheme` theo `WidgetState.selected`
  (`primary` / `iconNav`), rail thêm `selectedIconTheme`/`unselectedIconTheme` + nhãn. Test `icon_contrast_test.dart`
  (bar + rail + cặp container, Sáng/Tối) đỏ → xanh. **STD-SYNC**: `.standards` v5.1.0; CI app `flutter analyze
  --fatal-infos`, kiểm `git status --porcelain` sạch sau dựng (job app + web), ngân sách JS web ≤ 170 KB gzip
  (`apps/web/scripts/check-budget.mjs` trong `build`), release chặn APK > 25 MB. CHƯA: `knip` + `cargo machete` (cần cài
  công cụ/phụ thuộc mới - chờ chủ dự án; LÀM XONG ở PR kế, xem dòng dưới), LCP/CLS (cần trình duyệt đo), dấu hiệu TsuDEV trước liên kết tsudev.com
  (BRAND_ASSETS 4.1.0 - PR kế), QR3 (chờ chủ dự án chốt phạm vi), DK2 (chờ duyệt nhãn).

### UI1 - bảng đo (token, nền thật; trước → sau)

| Màn | Thành phần | Trạng thái | Biểu tượng / nền | Sáng | Tối |
| --- | --- | --- | --- | --- | --- |
| Mọi tab | Thanh điều hướng dưới | đang chọn | trước `onSecondary` (trắng) / `bgHover` → sau `primary` / `primary` 14 % trên `bgSurface` | 1,19 → **4,45:1** | 1,21 → **6,21:1** |
| Mọi tab | Thanh điều hướng dưới | chưa chọn | `iconNav` / `bgSurface` | **7,01:1** | **9,17:1** |
| Mọi tab (màn rộng) | NavigationRail | đang chọn | như thanh dưới (trước thiếu `selectedIconTheme`) | 1,19 → **4,45:1** | 1,21 → **6,21:1** |
| Lịch sử | ChoiceChip khoảng thời gian | đã chọn | chữ `textPrimary` / `bgHover` (`secondaryContainer`) | **16,63:1** | **13,96:1** |

Ngưỡng: biểu tượng ≥ 3:1, chữ ≥ 4,5:1 (DESIGN_SYSTEM 1, ACCESSIBILITY 2). Số tính từ `tokens.g.dart`, khớp số test đo.

Máy thật SM-M325FV (bản profile): ảnh `logs/qa/20261124/p4-ui1-sang.png`, `p4-ui1-toi.png` - biểu tượng đang chọn xanh trên viên
xanh nhạt, chưa chọn rõ trên nền thanh, hai chế độ. Chip đã chọn đổi từ nền xanh + chữ trắng sang nền `bgHover` + ✓ + chữ
đậm (theo `secondaryContainer` mới).
- 24/11/2026 - sound-db-c9: **Clean Codebase xong**: `knip` 6.44.2 (devDependency ghim, bản đã ra ≥ 2 tuần) + `knip.json`
  (điểm vào thật: script Astro, `public/*.js`, test vitest khai tay) ⇒ xoá mã chết `langCua` (web i18n), `now` (crypto.ts),
  bỏ 17 `export` + 1 kiểu export thừa ở sync-api; khai `sharp` 0.35.5 cho script thương hiệu (trước mượn của Astro).
  `cargo-machete` 0.9.2 `--locked`: 0 phụ thuộc thừa. CI: `npm run knip` (job web) + `cargo machete` (job Rust).
- 24/11/2026 - sound-db-c9: UI1 chuyển sang theme dùng chung `tsudev_ui` v0.3.0 (`TsuNavColors` + `tsuNavigationBarTheme`/
  `RailTheme` + `tsuCompleteContainers`) - bỏ bản tự viết; test tương phản vẫn xanh. **LG2 deploy production** (run
  Deploy 0010f32): ảnh Edge 1280 px `logs/qa/20261124/p5-lg2-web-{sang,toi}.png` - logo header không ô nền ở cả hai chế độ.
- 24/11/2026 - sound-db-c9: **QR3 CHƯA LÀM ĐƯỢC - bị chặn bởi QR1-IdP + QR2-UI** (đo 16:30): `POST tsudev.com/api/xd/sessions`
  404, discovery chưa có `tsudev_cross_device_endpoint`; `tsudev_ui` v0.3.0 chưa có `TsuSignInScreen`/`TsuQrScanner`/
  `TsuCrossDeviceApprove`. CROSS_DEVICE_LOGIN mục 2 CẤM RP tự dựng ⇒ không làm tạm. **Điểm IdP phải chốt trước khi Sound Db
  làm QR3** (gửi phiên tsudev/QR2): Sound Db là RP qua MÁY CHỦ (ADR-0003 - máy chủ giữ PKCE verifier, đổi mã ở token
  endpoint, app không cầm token tsudev). Chuẩn mục 5 gắn mã uỷ quyền với `jkt` khoá DPoP TẠM của thiết bị mới ⇒ máy chủ
  không có khoá đó thì không đổi được mã. Hướng đề xuất: (a) thiết bị mới = app Sound Db gọi `claim`/`verify` với
  `client_id=sounddb`, `redirect_uri=https://sound.tsudev.com/auth/callback`, `code_challenge` do MÁY CHỦ sinh (máy chủ
  tạo `login_requests` như luồng thường, trả cho app `state` + `code_challenge`), IdP KHÔNG gắn `jkt` cho mã khi client
  là confidential (xác thực client thay cho DPoP); app nộp `code`+`state` về `/auth/app/xd-callback` để máy chủ đổi mã
  rồi cấp token app như cũ. (b) Vai xác nhận Đ2 trong app Sound Db cần access token tsudev + DPoP - app KHÔNG có (ADR-0003)
  ⇒ Sound Db chỉ làm vai "thiết bị mới" (Đ1), vai xác nhận để app tsudev chung. Cần ADR-0008 khi IdP chốt.
- 24/11/2026 - sound-db-c9: **QR3 làm xong phần của app** (sau khi tsudev_ui v0.4.0 + tsudev#374 deploy, chuẩn
  CROSS_DEVICE_LOGIN v1.1.0 bỏ DPoP cho mã): `TsuSignInScreen` thay nút đăng nhập ở Cài đặt; "Quét để đăng nhập" (Đ1,
  Android/iOS) ⇒ `TsuXdLink.parse` ⇒ mở `/x/<id>` trong trình duyệt hệ thống ⇒ "Tiếp tục đăng nhập" theo ADR-0003 (không
  đổi máy chủ). Vai xác nhận Đ2 không làm (app không giữ token tsudev). ADR-0008. Test `qr_sign_in_test.dart` 13 ca (T9).
  `mobile_scanner` 7.5.0 ML Kit unbundled: APK release arm64 23,0 MiB, x64 **24,5 MiB** (ngưỡng 25 MiB - còn ~0,5 MiB).
  CHƯA: E2E Đ1 trên máy thật (cần máy tính đăng nhập tài khoản tsudev thật - 👤; điện thoại đang rút).
