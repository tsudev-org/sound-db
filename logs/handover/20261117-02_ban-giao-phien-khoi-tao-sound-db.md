# PHIẾU BÀN GIAO - Kết thúc phiên khởi tạo Sound Db (agent-sound)

- **Mã phiếu**: 20261117-02
- **Từ**: agent-sound (phiên `projects-b2`) - **Đến**: phiên kế tiếp của repo `sound-db`
- **Thời điểm**: 12:40 17/11/2026
- **Trạng thái**: MỞ
- **Nhánh git**: `main` sạch, đã đẩy (commit cuối `ee7cde2` trở đi). Không nhánh dở trong repo này.

## 1. Việc đã làm xong (chi tiết: `logs/STATE.md` mục Đã hoàn thành)

- Toàn bộ dự án: lõi DSP Rust + WASM, bản Dart khớp vector, app Flutter 5 nền tảng, máy chủ Workers + D1, website.
- Production https://sounddb.tsudev.com (Worker `sound-db`, D1 `sound-db` apac, secret đã đặt). Nghiệm thu: máy đo
  web đọc tông 1 kHz -20 dBFS = 77,0 dB / 1,000 kHz; bộ kiểm Playwright + axe 9 trang × Sáng/Tối × PC/điện thoại:
  0 lỗi (trừ 404 đúng thiết kế); bảng điều khiển đã đăng nhập kiểm bằng dữ liệu mẫu ở local.
- Phát hành: v26.11.1701, **v26.11.1702** (Windows/macOS/Linux, SHA256SUMS + chứng thực nguồn gốc).
- Kênh cài: Scoop `tsudev-sound-db` 26.11.1702 (scoop-bucket #16, #18), Homebrew cask (homebrew-tap #8, tự cập nhật
  lên 26.11.1702). CI 6 job xanh, ruleset `main-bao-ve` bắt buộc cả 6.
- tsudev đã sửa host OIDC (#297) và thêm thẻ Sound Db ở tsudev.com/apps (#298).

## 2. Việc dang dở + bước tiếp theo CỤ THỂ

- [ ] **linux-packages PR #30** (thêm `tsudev-org/sound-db` vào `products.json`): cài thử ĐẠT trên ubuntu:24.04,
  debian:13, arm64; HỎNG debian:12 và ubuntu:22.04 (fedora:latest đang chạy lúc bàn giao). Giả thuyết: bản Linux
  dựng trên `ubuntu-24.04` cần glibc 2.39 trong khi deb khai `libc6 (>= 2.34)`. Kiểm:
  `gh run view <id> --repo tsudev-org/linux-packages --log-failed | grep -iE "LOI|GLIBC"`. Sửa một trong hai:
  (a) dựng job `linux` của `.github/workflows/release.yml` trên `ubuntu-22.04` (glibc 2.35, hợp cả 4 bản) - khuyến
  nghị; hoặc (b) nâng `linux.deb.depends` lên `libc6 (>= 2.39)` + rpm tương ứng và chấp nhận bỏ bản cũ. Sau đó tag
  bản mới (vd `v26.11.1801`), chạy lại check PR #30, merge; workflow `xuat-ban` cần chủ dự án duyệt Environment
  `packages`. Khi kho có gói: chuyển `apt`,`rpm` từ `planned` sang `channels` trong `packaging/package.json` và
  thêm lệnh vào `LENH` của `apps/web/src/pages/tai-ve.astro`.
- [ ] **scoop-bucket PR #17** (sửa excavator: token `SCOOP_GH_TOKEN`, lỗi 403 không còn thành "Khong co ban moi",
  gỡ thử chịu khóa lối tắt): ⛔ cần chủ sở hữu `nguyentrangtinhsu` Approve (cổng Bảo vệ bản quyền). Đừng merge
  bằng `--admin`.
- [ ] 👤 Chủ dự án chạy SQL OAuthClient `sounddb` (phiếu tsudev `20261117-SD1`, bản gốc `20261117-01`). Trước khi
  có client, `/auth/web/start` chuyển tới tsudev nhưng tsudev sẽ báo client không tồn tại. Sau khi có: đăng nhập thử
  web + app, nghiệm thu đồng bộ hai thiết bị.
- [ ] 👤 Khóa ký Android (4 secret Environment `release`) ⇒ bản sau có APK. 👤 Secret Cloudflare cho workflow
  Deploy (hiện triển khai bằng `npx wrangler deploy` trong `services/sync-api` từ máy dev đã đăng nhập).
- [ ] winget (`tsudev.SoundDb`, đã khai ở `packaging/package.json`): PR vào microsoft/winget-pkgs - bộ phân loại
  từng chặn, để chủ dự án.
- [ ] Logo riêng: đề xuất cho chủ dự án duyệt (`BRAND_ASSETS.md` mục 15); có logo thì thay
  `assets/brand/source/`, sửa `assets/brand/brand.json`, chạy `node apps/web/scripts/brand-assets.mjs`, báo tsudev.

## 3. File liên quan / đang khóa

Không file nào đang khóa (`logs/LOCKS.md` trống). Không tiến trình nền nào còn chạy.

## 5. Cảnh báo và quyết định quan trọng

- Ghi đủ ở `AGENTS.md` mục B.5 (npm >= 11; `.gitignore` chuẩn chặn thư mục `core`; Worker chỉ export handler; CSP
  `/do/` do Worker đặt; `wrangler dev --local-upstream localhost:8787` + `PUBLIC_ORIGIN` trong `.dev.vars`; tài khoản
  Cloudflare hết cron Free).
- Dựng lại `apps/web/dist` khi `wrangler dev` đang chạy làm nó sập - dừng dev trước.
- `pkill -f "<chuỗi>"` giết luôn chính shell đang chạy lệnh có chuỗi đó - dùng `pgrep` lấy PID rồi `kill`.
- `~/.config/tsudev/cloudflare.env` (token từ 16/11, của phiên khác) có quyền 644 - nên `chmod 600` hoặc thu hồi.
- Bộ kiểm trình duyệt dùng lại được: Playwright + axe nằm ở `~/projects/lotus-share/website/node_modules`
  (script mẫu đã dùng trong phiên này không được lưu vào repo - viết lại theo mô tả ở mục 1 nếu cần).

## 6. Trạng thái cổng kiểm

`./scripts/check-standards.sh` đạt; CI `main` 6/6 xanh; `cargo test` 12, `dart test` 6, `flutter test` 9,
`vitest` 17 đều đạt; `npm audit` 0.
