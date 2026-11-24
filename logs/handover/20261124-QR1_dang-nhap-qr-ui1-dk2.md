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
  công cụ/phụ thuộc mới - chờ chủ dự án), LCP/CLS (cần trình duyệt đo), dấu hiệu TsuDEV trước liên kết tsudev.com
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
