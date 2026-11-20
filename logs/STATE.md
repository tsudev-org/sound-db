# STATE.md - Trạng thái project Sound Db

> **Phiên kế tiếp (phiếu toàn hệ 20261117-P2):** đọc `~/projects/logs/handover/20261117-P2_ke-hoach-phan-phoi-tin-cay-da-nen-tang.md` hàng 2 (`sound-db`) ở mục 3
> + `.standards/docs/DISTRIBUTION_TRUST.md` (chuẩn v3.7.0) + `.standards/docs/VERSIONING.md` mục 2. Khuôn thẻ/tên tệp mới chỉ áp
> cho bản phát hành KẾ TIẾP, đọc mục 2.4 (updater đã cài) trước khi đổi.

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] 👤 **Duyệt ADR-0006** (chuyển đồng bộ sang tsusync, mã hoá đầu cuối, mật khẩu đồng bộ riêng) + duyệt triển khai
  tsusync với `NAMESPACES` gồm `sounddb`. Kế hoạch E1-E5 + điều kiện P1-P4: phiếu `logs/handover/20261120-E2E1_*`.
  Chưa đủ P1-P3 ⇒ KHÔNG bắt đầu E1.
- [ ] 👤 Nghiệm thu Pro bằng tài khoản tsudev thật: đăng nhập web → Tài khoản hiện "Bản miễn phí"/"TsuDEV Pro tới ...";
  `wrangler tail` không có `entitlements_unavailable`. (Khoá RP đã đăng ký - đo 20/11, phiếu PRO2 mục 5.)
- [ ] Play Billing `tsudev_pro`/`nam` + ủng hộ trong app bản Play (chờ tsudev B2).
- [ ] `NSMicrophoneUsageDescription` tiếng Anh (`en.lproj/InfoPlist.strings`) - cần phiên trên macOS (AGENTS.md B.4).
- [ ] TR1-b: hồ sơ OpenSSF Best Practices cho sound-db (bestpractices.dev, cần đăng nhập GitHub của chủ dự án).

- [ ] **ƯU TIÊN 1 - Kiểm thử toàn diện trên smartphone thật qua adb** (5 phase: kết nối + smoke, chức năng từng tab,
  phi chức năng + bảo mật, sửa lỗi + chuẩn hoá mã, phát hành bản sửa). Kế hoạch + lệnh + tiêu chí:
  `logs/handover/20261117-06_ke-hoach-kiem-thu-smartphone-adb.md`. 👤 cần bật Gỡ lỗi không dây và chạy `adb pair`.
- [ ] 👤 Đăng nhập tsudev: ĐÃ HẾT TẮC (22:20 17/11) - `/auth/web/start` → `/oidc/auth` 303 → `/oidc/interaction/<uid>`
  307 → `tsudev.com/login` 200. Còn nghiệm thu bằng tài khoản tsudev thật của chủ dự án: đăng nhập web
  (sounddb.tsudev.com → Đăng nhập) + app, rồi đồng bộ hai thiết bị. Agent không có tài khoản ⇒ không tự làm được.
- [ ] 👤 Required reviewers cho Environment `release` và `production` (tài khoản `tsudev-tsudev` không có quyền admin
  repo - HTTP 403). Lệnh: phiếu `20261117-05` mục 3.
- [ ] 👤 Duyệt `xuat-ban` của linux-packages khi có run mới cho 26.11.1705.
- [ ] Phiếu V1 (khuôn phiên bản thống nhất): chờ `tsudev-standards` v3.7.0 ⇒ sync, bản chuyển tiếp phát hành cả
  tên tệp cũ + mới (`{os}-{arch}`, `SHA256SUMS.txt`), phiếu cho scoop-bucket + homebrew-tap. Kế hoạch: phiếu V1 mục 6.
- [ ] winget: PR vào microsoft/winget-pkgs (bộ phân loại từng chặn - để chủ dự án)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

- 20/11/2026 - `sound-db-67`: **i18n tiếng Anh** cho app + web (PR #22): ARB vi/en 202 khoá, lần đầu theo ngôn ngữ
  hệ thống (chưa hỗ trợ ⇒ en), Cài đặt → Ngôn ngữ, máy đã cài giữ vi; web `/en/*` + `lang.js` tự chọn lần đầu, hreflang,
  `/en/do/` qua Worker. Sửa tràn 12 px chân bảng ở màn 360 px. App 30 test, web check-dist kiểm điều khoản Pro vi + en.
  **Khoá RP `sounddb` trên tsudev đã đăng ký** (kênh trạng thái 200), phiếu PRO2 đóng; production D1 chưa có người dùng.
  **ADR-0006 + phiếu E2E1** (ĐỀ XUẤT): chuyển đồng bộ sang tsusync. adb: chưa có thiết bị ghép.

- 20/11/2026 - `sound-db-28`: **PRO1 + PRO2** (ADR-0005, quy ước v4.1.0): đồng bộ đám mây là TsuDEV Pro - gate
  `402 pro_required` ở máy chủ, quyền lợi qua kênh RP tsudev (`private_key_jwt`, đệm 24 giờ, JWS kiểm đủ), xoá có xác
  minh qua kênh trạng thái; app `tsudev_ui` v0.2.0 (không đẩy khi miễn phí, màn Pro/Ủng hộ, nhắc gia hạn 7.6, nhiều
  thiết bị 7.3, huy hiệu); web khối Gói Pro. Máy chủ 36 test, app 20 test. **LG1**: logo riêng Sound Db (PR #20) cho
  web + icon mọi nền tảng, dây chuyền `crop` bỏ dấu ✦.

- 17/11/2026 - Cài thử APK `sound-db_26.11.1705_x64-setup.apk` (SHA256 khớp) trên emulator Android 16 x86_64 (AVD
  `sounddb36`): cài đạt, versionName 26.11.1705 / versionCode 26115705, app mở màn Đo mức đúng giao diện, không lỗi
  Flutter/crash của app. Bấm Bắt đầu đo hiện hộp xin quyền micro. ANR chỉ của systemui/gms (máy quá tải). Emulator
  chạy qua `wsl.exe -e <script>` để nhận nhóm `kvm` mới cấp mà không phải khởi động lại phiên.

- 17/11/2026 - Scoop lên 26.11.1705 (excavator 44106910857 đạt; 403 rate limit lần trước là tạm thời). Phiếu V1: đã
  đối chiếu - thẻ, tiêu đề Release, phiên bản trong app/web, versionCode đúng khuôn; tên tệp + `SHA256SUMS` lệch, kế
  hoạch chuyển tiếp ở phiếu V1 mục 6. OIDC vẫn tắc (`tsudev.com/oidc/interaction/*` 404 lúc 21:45).

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
- 20/11/2026 - TsuDEV Pro: gate 402 máy chủ, kênh RP, xoá có xác minh: `docs/adr/0005-*`
- 20/11/2026 - (ĐỀ XUẤT) Đồng bộ sang tsusync, mã hoá đầu cuối: `docs/adr/0006-*`
- 17/11/2026 - Dùng logo tsudev chung cho tới khi có logo riêng được duyệt.

## Sự cố bảo mật

- (chưa có)
