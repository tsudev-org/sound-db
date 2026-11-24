# PHIẾU BÀN GIAO 20261124-07 - sound-db, cuối phiên `sound-db-c9` (24/11/2026)

- **Từ**: agent-sound phiên `sound-db-c9` - **Đến**: phiên agent-sound kế tiếp (+ 👤 chủ dự án ở mục 3)
- **Thời điểm**: 18:00 24/11/2026 - **Trạng thái**: MỞ
- **Git**: `main` sạch, đã đẩy (CI + Deploy xanh); không nhánh dở; `logs/LOCKS.md` trống; không tiến trình nền của phiên
  (gradle daemon đã dừng; adb server đang chạy là của phiên điều phối `projects-71` - ĐỪNG tắt).
- **Phiếu liên quan**: `20261117-06` mục 6 (QA-01..11, kết quả máy thật), `20261124-QR1` (UI1/STD-SYNC/QR3/DK2 - bản sao
  repo), `20261124-LG2`, `20261123-SEC1` (ĐÓNG), ADR-0008. AKB: `SES-20261124-0044-3111` + ISS/LES ngày 20261124.

## 1. Đã xong trong phiên (PR #41-#51, đều đã merge)

| Việc | PR | Ghi chú |
| --- | --- | --- |
| SEC1 nhận bí mật bằng `tsu-nhan-bi-mat` | #41 | phiếu SEC1 ĐÓNG, bảng tên bí mật mục 3 |
| Tìm/lọc Lịch sử app + web (không dấu, khoảng thời gian) | #41 | DB app v3, migration D1 `0003` (đã áp production) |
| QA-06 đóng (không đổi offset), QA-07..10 sửa + thử máy thật; QA-11 MỞ | #41 | phiếu 06 mục 6 |
| UI1 tương phản biểu tượng điều hướng (1,19 → 4,45:1), dùng `TsuNavTheme` | #44, #47 | `test/icon_contrast_test.dart` |
| Chuẩn v5.1.0 + cổng CI: `--fatal-infos`, cây sạch, ngân sách JS/APK, knip, cargo-machete | #44, #46 | |
| LG2 logo vector xoá nền + dấu TsuDEV trước liên kết tsudev.com; web đã deploy | #45 | nguồn SVG ghi ở AGENTS B.4 |
| QR3 đăng nhập QR (vai thiết bị mới) + `TsuSignInScreen` | #51 | ADR-0008, `test/qr_sign_in_test.dart` |
| Token Cloudflare mới (có D1) cho Deploy | - | `~/.config/tsudev/cloudflare-sounddb.env` (600) + Environment `production` |
| Sự cố: merge NHẦM Dependabot #48 ⇒ revert #50 | #50 | production không đổi; AKB `ISS-20261124-1737-ec91` |

Số đo nền (để so ở phiên sau): app 72 test, máy chủ 45 test; APK release arm64 **23,0 MiB**, x64 **24,5 MiB** (ngưỡng CI
25 MiB - còn ~0,5 MiB); JS web ban đầu lớn nhất 6,0 KB gzip; khởi động nguội 0,95-1,2 s (23/11).

## 2. Việc còn lại - làm theo thứ tự

1. **Phát hành bản sửa** (phiếu 06 Phase 5) gồm QA-07..10, tìm/lọc, UI1, LG2 (icon app mới), QR3. Phiên bản theo
   `.standards/docs/VERSIONING.md`: `26.11.DDNN` ngày phát hành; versionCode arm64 = số dựng + 2000 PHẢI > **26114303**
   (bản thử đang cài trên SM-M325FV). Kiểm: CI release (bước chặn APK > 25 MiB), VirusTotal, `sha256sum -c SHA256SUMS.txt`
   + `gh attestation verify`, cài đè trên máy thật giữ dữ liệu (Lịch sử 3 phiên thử ở gói `.profile`, dữ liệu thật ở gói
   chính). Ghi chú phát hành vi + en, không câu "do AI". Tên tệp cũ + chuẩn vẫn song song (V1 bước 3-4 chưa xong).
2. **QA-11 CPU khi đo ~0,9 lõi** (phiếu 06 mục 6): đo hồ sơ CPU bản profile (DevTools) xem khâu nào - lọc A/C/Z, dàn
   1/3 octave ở 48 kHz, FFT; hướng: dàn octave nhiều tầng hạ mẫu (IEC 61260-1) và/hoặc isolate riêng. Đổi thuật toán ⇒
   Rust tham chiếu + `conformance/vectors.json` + Dart CÙNG PR (AGENTS B.3). Đo lại bằng `cpu_rate` (`scripts/android/ui.sh`),
   mục tiêu < 0,3 lõi ở Đo mức. Cân nhắc ADR (LANGUAGE_SELECTION 5.1: viết lại sang Rust FFI cần ADR + số đo trước/sau).
3. **Dependabot npm** (sẽ mở lại sau revert #48): KHÔNG nhận TypeScript 7.x / vitest 5.x tới khi `@astrojs/check` hỗ trợ
   TS 7 và `@cloudflare/vitest-pool-workers` hỗ trợ vitest 5 (lỗi cụ thể ở AKB ISS-20261124-1737-ec91). Các bản vá khác
   (jose, astro patch, wrangler) nhận được nếu CI xanh - tách nhóm hoặc ghim `ignore` trong `.github/dependabot.yml`.
4. Việc 👤 (mục 3) - chuẩn bị sẵn lệnh, chờ chủ dự án.
5. Hàng đợi cũ trong `logs/STATE.md` (ADR-0006/tsusync, GP1, V1 bước 3-4 chờ ba repo đóng gói, Play Billing, winget...).

## 3. Việc của chủ dự án (👤)

- **QR3 E2E**: trên máy tính đăng nhập tsudev.com ⇒ Tài khoản ⇒ Đăng nhập trên điện thoại ⇒ app Sound Db (bản mới) ⇒
  Cài đặt ⇒ Đăng nhập ⇒ "Quét để đăng nhập". Agent chỉ dẫn + chụp màn hình, không cầm mật khẩu.
- **TalkBack nghe thật**: bật TalkBack, vuốt qua Đo mức khi đang đo - chỉ đọc vùng mức khi đổi, không đọc dồn (QA-05).
- **Cắm điện thoại** (adb.exe Windows, USB). Nếu "unauthorized": thu hồi uỷ quyền gỡ lỗi USB, tắt/bật Gỡ lỗi USB, cắm lại,
  tích "Luôn cho phép". ĐỪNG để agent chạy `adb usb`.
- DK2 (nhãn tín nhiệm), Pro nghiệm thu bằng tài khoản thật, Required reviewers Environment - như STATE.

## 4. Bẫy đã gặp (đọc trước khi làm - chi tiết ở AGENTS.md B.5 + AKB)

- Chờ/merge PR theo **TÊN NHÁNH** (`gh pr checks <nhánh>`, `gh pr merge <nhánh>`), chỉ merge khi `[ "$bad" = 0 ]`;
  KHÔNG ghi cứng số PR (sự cố #48). Không merge PR của Dependabot/người khác khi chưa được giao.
- Chỉ `dart format` tệp mình sửa (định dạng cả `lib` làm 27 tệp đổi).
- Vòng `until` chờ kết quả phải dò mẫu chắc chắn có (một lần treo vì dò sai mẫu); ưu tiên `run_in_background` + thông báo.
- `npx --yes <gói chưa ghim>` bị hệ thống quyền chặn ⇒ cài devDependency `--save-exact` bản ≥ 2 tuần tuổi, so lock trước/sau.
- `gh run cancel` lượt Deploy bị chặn - đừng lách; Deploy có bước test TRƯỚC triển khai nên CI đỏ không lên production.
- Máy thật: `flutter drive` cài lại gói ⇒ mất quyền micro; `uiautomator dump` hỏng khi đang đo (bấm toạ độ 875,157);
  dùng `tapx` cho nhãn chính xác; DevTools Chrome ở `chrome_devtools_remote_<pid>` (socket không hậu tố là Edge),
  client CDP chạy `node.exe`; ảnh Tối của web: Edge headless `--blink-settings=preferredColorScheme=0`.
- Deploy cần token có **D1 Edit** (7403 = thiếu quyền dịch vụ, không phải sai Account ID).
- `mobile_scanner` giữ `useUnbundled=true`; thêm phụ thuộc native nào cũng phải đo APK x64 (còn ~0,5 MiB).

## 5. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán nguyên văn)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Làm đúng thứ tự, không bỏ bước, trả lời tiếng Việt.

1. KHỞI ĐỘNG (chỉ đọc phần liên quan, không đọc lại tệp vừa ghi):
   CLAUDE.md, AGENTS.md (B.4, B.5), logs/STATE.md, logs/LOCKS.md, phiếu logs/handover/20261124-07_ban-giao-sound-db.md
   (VIỆC CHÍNH - mục 2 theo thứ tự, mục 4 bẫy), rồi phiếu 20261117-06 mục 6 khi làm QA. `akb start "<mục tiêu>"`,
   `akb search` trước khi tự mò. `git status`, `git log --oneline -5`, `gh pr list` (PR của Dependabot: ĐỌC, không tự
   merge - xem phiếu 07 mục 2.3). ListAgents (phiên khác có thể đang dùng điện thoại adb RF8T80J6WVF).
2. GHI KHOÁ + dòng "Đang thực hiện" trong STATE trước khi sửa; nhả khoá ngay khi xong.
3. LÀM phiếu 07 mục 2: (1) phát hành bản sửa, (2) QA-11 CPU, (3) Dependabot, rồi hàng đợi STATE. Việc 👤 (mục 3):
   chuẩn bị lệnh, hỏi tôi một lần bằng câu hỏi gộp, không chờ vô ích - làm việc khác trong lúc chờ.
4. NGUYÊN TẮC: mọi kết luận có bằng chứng (số đo/ảnh/log); lỗi ⇒ QA-nn ở phiếu 06 ⇒ test đỏ ⇒ sửa tận gốc ⇒ xanh;
   Rust là tham chiếu DSP; không sửa .standards/; không tạo/đổi tên repo theo tên cũ; bí mật chỉ qua tsu-nhan-bi-mat;
   không câu "do AI"/Co-Authored-By trong commit, PR, tài liệu, ghi chú phát hành.
5. PR/CI: mỗi vùng một PR; chạy cổng tại máy phần bị sửa trước khi đẩy; chờ CI và merge theo TÊN NHÁNH, chỉ khi 0 check
   không đạt; job macOS bị huỷ không bước nào ⇒ `gh run rerun --failed`; không chạy lệnh flutter song song với gradle;
   bản dựng thử tại máy: --build-number ĐÚNG versionCode bản sắp phát hành (không cao hơn).
6. KẾT THÚC: phiếu 06 + STATE + phiếu bàn giao mới `logs/handover/<YYYYMMDD>-NN_*.md` (khuôn như phiếu 07, có prompt
   cho phiên sau), PR + merge, `akb close` + `akb sync --project sound-db`, main sạch, LOCKS trống, dừng tiến trình nền
   do chính phiên tạo (không tắt của phiên khác).
```
