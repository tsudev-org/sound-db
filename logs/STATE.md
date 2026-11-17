# STATE.md - Trạng thái project Sound Db

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] 👤 Đăng ký client OIDC `sounddb` ở tsudev (phiếu tsudev `20261117-SD1`; phiên tsudev không có `neon.env` ⇒ chỉ
  chủ dự án chạy SQL được). Xong ⇒ agent nghiệm thu đăng nhập web + app, đồng bộ hai thiết bị.
- [ ] 👤 Required reviewers cho Environment `release` và `production` (tài khoản `tsudev-tsudev` không có quyền admin
  repo - HTTP 403). Lệnh: phiếu `20261117-05` mục 3.
- [ ] 👤 Chọn logo riêng (phiếu `logs/handover/20261117-04_de-xuat-logo-rieng-sound-db.md`, 3 phương án SVG).
- [ ] 👤 Duyệt `xuat-ban` của linux-packages khi có run mới cho 26.11.1705.
- [ ] winget: PR vào microsoft/winget-pkgs (bộ phân loại từng chặn - để chủ dự án)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

- 17/11/2026 - Bản 26.11.1705: APK Android ký số (arm64, x86_64) lần đầu; sửa `build.gradle.kts` (`java.util.Properties`
  không giải được trong khối android {} - job Android sẽ hỏng ngay lần ký thật). Khóa ký ở
  `~/.config/tsudev/android/` (600), 4 secret ở Environment `release`. Secret Cloudflare ở `production`; Deploy tự
  động khi đẩy main (run 44097415902 đạt nghiệm thu). Homebrew 26.11.1705. Phiếu `20261117-05`.

- 17/11/2026 - Kênh APT/DNF (pkg.tsudev.com) có Sound Db 26.11.1704; /tai-ve/ hiện lệnh từ catalog.json. scoop-bucket
  #17 merge (excavator đạt), Scoop + Homebrew ở 26.11.1704.

- 17/11/2026 - Bản 26.11.1704: bản Linux dựng trên ubuntu-22.04 (GLIBC cao nhất 2.34, có bước chặn hồi quy) - chạy
  được trên Debian 12/Ubuntu 22.04. linux-packages #30 đạt 12/12, đã merge; chờ duyệt xuất bản. Web đã deploy.
  Phiếu: `logs/handover/20261117-03_ban-giao-sua-glibc-linux-26.11.1704.md`.

- 17/11/2026 - Bản 26.11.1702 (sửa Lịch sử, đăng nhập không WebView, iOS mode đo lường). Scoop + Homebrew đã ở
  26.11.1702. Phiếu bàn giao cuối phiên: `logs/handover/20261117-02_ban-giao-phien-khoi-tao-sound-db.md`.

- 17/11/2026 - Scoop `tsudev-sound-db` (scoop-bucket#16, cài thử thật trên Windows đạt) và Homebrew cask (homebrew-tap#8, cài thử trên macOS đạt), tự cập nhật theo Release. iOS mode `.measurement`; CI thêm job dựng kiểm iOS + macOS (bắt buộc trong ruleset). `packaging/package.json`, khối Cài bằng lệnh trên /tai-ve/.

- 17/11/2026 - Đợt kiểm thử trình duyệt + app (Playwright, axe, test toàn app Flutter 2 cỡ màn hình). Lỗi đã sửa:
  (1) NGHIÊM TRỌNG: truy vấn Lịch sử dùng `json_extract(data, "$.started_at")` nháy kép - SQLite mới coi là tên
  cột, trang Lịch sử hỏng trên máy thật; (2) web: nội dung dính mép điện thoại (padding `... 0` đè lề `.khung`);
  (3) bảng điều khiển tràn ngang 111px do nhãn ẩn `.an-di` neo theo khung trang; (4) lệnh ghi lỗi không báo người
  dùng; (5) đua phản hồi khi bấm chuyển trang nhanh; (6) console 401 khi là khách (thêm `/api/v1/auth/status`);
  (7) `<pre>` không dùng được bàn phím; (8) app: nhãn tần số phổ đồ tràn 25px, chân bảng phân trang tràn 27px trên
  điện thoại, tra AppScope trong dispose(); (9) tạo plugin thu âm/phát lười. Đạt: header/footer nhất quán mọi trang,
  tên tài khoản hiển thị đúng 1 lần, chống XSS (nhãn/thiết bị chứa thẻ HTML hiển thị như chữ).

- 17/11/2026 - Bản phát hành 26.11.1701 (Windows/macOS/Linux) trên GitHub Releases, SHA256SUMS + chứng thực nguồn
  gốc (đã `gh attestation verify` đạt). CI 5 job xanh; ruleset `main-bao-ve`. Bỏ flutter_web_auth_2 (WebView nhúng):
  di động dùng app_links, desktop dùng vòng lặp 127.0.0.1. iOS/macOS dựng trên macos-26.

- 17/11/2026 - Repo `tsudev-org/sound-db` (Public, secret scanning + push protection + Dependabot). Production
  sounddb.tsudev.com: Worker `sound-db` + D1 `sound-db` (apac, id cfcceb24-...), secret đặt. Nghiệm thu: health ok,
  `/do/` một CSP có WASM, `/api/v1/me` 401, máy đo trên Chromium với tông 1 kHz -20 dBFS đọc 77,0 dB / 1,000 kHz.
  tsudev đã sửa host OIDC (#297) và thêm thẻ Sound Db ở tsudev.com/apps (#298). npm audit 0 lỗ hổng (overrides).

- 17/11/2026 - Khởi tạo toàn bộ dự án (agent-sound): lõi DSP Rust + WASM (12 test độ chính xác IEC), bản Dart khớp
  vector đối chiếu, app Flutter 5 nền tảng (APK Android dựng được, 7 test app), máy chủ Workers + D1 (17 test),
  website + máy đo trên trình duyệt (nghiệm thu đầu-cuối tông 1 kHz đọc đúng 77,0 dB), CI/CodeQL/deploy/release,
  tài liệu kiến trúc + 4 ADR.

## Quyết định quan trọng

- 17/11/2026 - Monorepo, Rust tham chiếu + Flutter + Astro + Workers/D1: `docs/adr/0001-*`
- 17/11/2026 - App dùng bản Dart khớp vector đối chiếu thay vì Rust FFI: `docs/adr/0002-*`
- 17/11/2026 - Đăng nhập đi qua máy chủ Sound Db (IdP tsudev dùng token mờ, tắt CORS, chưa có client native): `docs/adr/0003-*`
- 17/11/2026 - Đồng bộ ghi sau thắng, con trỏ `rev`: `docs/adr/0004-*`
- 17/11/2026 - Dùng logo tsudev chung cho tới khi có logo riêng được duyệt.

## Sự cố bảo mật

- (chưa có)
