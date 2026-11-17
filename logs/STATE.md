# STATE.md - Trạng thái project Sound Db

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] 👤 Đăng ký client OIDC `sounddb` ở tsudev (phiếu `logs/handover/20261117-01_yeu-cau-dang-ky-client-oidc-tsudev.md`)
- [ ] 👤 Secret `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` ở Environment `production` rồi bật lại trigger `push`
  trong `.github/workflows/deploy.yml` (hiện triển khai bằng `wrangler` đã đăng nhập trên máy dev)
- [ ] Branch protection/ruleset cho `main` (check bắt buộc: CI các job, CodeQL)
- [ ] 👤 Khóa ký Android (keystore) đặt vào Environment `release`, rồi tag bản đầu
- [ ] iOS: kênh nền tảng đặt `AVAudioSession.Mode.measurement` (plugin record không lộ tham số)
- [ ] Kênh cài bằng lệnh (Scoop, Homebrew, winget, APT/RPM) sau bản phát hành đầu (`PACKAGING.md`)
- [ ] Logo riêng cho Sound Db: đề xuất cho chủ dự án duyệt (`BRAND_ASSETS.md` mục 15)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

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
