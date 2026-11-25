# STATE.md - Trạng thái project Sound Db

> **PHIÊN KẾ TIẾP ĐỌC TRƯỚC:** `logs/handover/20261125-11_ban-giao-sound-db.md` (việc 👤 có agent hỗ trợ: Required
> reviewers, worktree qa11, Pro, QR3, TalkBack; rồi QA-11 quyết định đóng/làm tiếp; bẫy mục 3). Phiên `sound-db-ff` kết
> thúc trưa 25/11/2026, main sạch, LOCKS trống, chuẩn v6.0.0. Điện thoại SM-M325FV đang cắm (adb.exe thấy máy).

> **Phiên kế tiếp (phiếu toàn hệ 20261117-P2):** đọc `~/projects/logs/handover/20261117-P2_ke-hoach-phan-phoi-tin-cay-da-nen-tang.md` hàng 2 (`sound-db`) ở mục 3
> + `.standards/docs/DISTRIBUTION_TRUST.md` (chuẩn v3.7.0) + `.standards/docs/VERSIONING.md` mục 2. Khuôn thẻ/tên tệp mới chỉ áp
> cho bản phát hành KẾ TIẾP, đọc mục 2.4 (updater đã cài) trước khi đổi.

> Agent đọc file này ở đầu mỗi phiên và cập nhật ở cuối mỗi phiên.
> Quy trình: `.standards/docs/AGENT_PROTOCOL.md`.

## Hàng đợi task (làm từ trên xuống)

- [ ] 👤 **Duyệt ADR-0006** (chuyển đồng bộ sang tsusync, mã hoá đầu cuối, mật khẩu đồng bộ riêng) + duyệt triển khai
  tsusync với `NAMESPACES` gồm `sounddb`. Kế hoạch E1-E5 + điều kiện P1-P4: phiếu `logs/handover/20261120-E2E1_*`.
  Chưa đủ P1-P3 ⇒ KHÔNG bắt đầu E1. Đo 20/11 23:10: ADR-0006 vẫn ĐỀ XUẤT; tsusync chưa deploy (`NAMESPACES` rỗng,
  sync.tsudev.com không phân giải), thẻ v0.2.0 chưa có máy khách Dart/TS ⇒ đã gửi phiếu `tsusync/logs/handover/20261120-SDB1_*`.
- [ ] 👤 Nghiệm thu Pro bằng tài khoản tsudev thật: đăng nhập web → Tài khoản hiện "Bản miễn phí"/"TsuDEV Pro tới ...";
  `wrangler tail` không có `entitlements_unavailable`. (Khoá RP đã đăng ký - đo 20/11, phiếu PRO2 mục 5.) Đo 20/11 23:15:
  D1 có 1 tài khoản (tạo 23:01, 1 phiên web) nhưng bảng `entitlements` RỖNG ⇒ chưa từng gọi `/api/v1/me` thành công
  hoặc kênh RP lỗi; tail 30 phút không có lượt mở trang Tài khoản. Từ bước B đổi tên miền: đăng nhập lại ở sound.tsudev.com.
- [ ] GP1 Google Play Console (`logs/handover/20261120-GP1_*`): 2.1 kiểm mã micro ĐẠT; bước 1-7 trên Play Console chưa làm.
- [ ] DM1 đổi tên miền: scoop-bucket #26 + homebrew-tap #13 đã đổi homepage; tsudev PR #348 (thẻ tsudev.com/apps, logo) chờ
  CI. Homepage trong .deb/.rpm (pkg.tsudev.com) tự đổi ở bản phát hành KẾ TIẾP - không cần làm gì thêm.
- [ ] Play Billing `tsudev_pro`/`nam` + ủng hộ trong app bản Play (chờ tsudev B2).
- [ ] `NSMicrophoneUsageDescription` tiếng Anh (`en.lproj/InfoPlist.strings`) - cần phiên trên macOS (AGENTS.md B.4).
- [ ] Phiếu V1 bước 3-4: chờ scoop-bucket, homebrew-tap, linux-packages chuyển sang tên tệp chuẩn (phiếu điều phối
  `~/projects/logs/handover/20261123-SDB-V1_*`) ⇒ đổi `packaging/package.json`, bỏ tên cũ ở `release.yml`. Đo 23/11
  19:55 (`gh api`): CHƯA repo nào chuyển; scoop + cask còn ở 26.11.1705 (chưa tự lên 26.11.2301) ⇒ giữ tên cũ.

- [ ] 👤 QR3 E2E trên máy thật: máy tính đăng nhập tsudev.com ⇒ Tài khoản ⇒ Đăng nhập trên điện thoại ⇒ app Sound Db
  "Quét để đăng nhập" (ADR-0008). DK2: chờ duyệt nhãn tín nhiệm. Dependabot npm (TS 7, vitest 5): cần `astro check` hỗ
  trợ TS 7 + `vitest-pool-workers` hỗ trợ vitest 5 trước khi nhận (PR #48 đã revert).
- [ ] **QA-11 quyết định** (phiếu 11 P2): sau bước 4 (PR #68) Đo mức bản profile 31-32, bản release 26.11.2501 29-31
  jiffies/s (gốc 72-83). Đề xuất 👤 chấp nhận ~0,3 lõi và đóng; nếu cần < 30 ⇒ tích luỹ 1/3 octave bằng dàn lọc hạ mẫu
  (Rust + vector + Dart cùng PR).
- [ ] **Việc 👤 có agent hỗ trợ** (phiếu 11 P1): Required reviewers ĐÃ BẬT (👤 chạy 25/11, AGENTS.md B.5), gỡ worktree sound-db-qa11 (CÒN thay đổi chưa commit - phải hỏi), Pro nghiệm thu, QR3 E2E,
  TalkBack. SignPath: đo 0/6 (25/11) ⇒ KHÔNG nộp.
- [ ] Phát hành bản kế tiếp (có QA-11 bước 4 + nền Sáng mới trong app + gói `.intoto.jsonl` tự đính kèm Release).
- [ ] 👤 TalkBack thật: bật TalkBack, vuốt qua Đo mức khi đang đo - chỉ đọc vùng mức khi đổi, không đọc dồn (QA-05).
- [ ] **ƯU TIÊN 1 - Kiểm thử toàn diện trên smartphone thật qua adb** (5 phase: kết nối + smoke, chức năng từng tab,
  phi chức năng + bảo mật, sửa lỗi + chuẩn hoá mã, phát hành bản sửa). Kế hoạch + lệnh + tiêu chí:
  `logs/handover/20261117-06_ke-hoach-kiem-thu-smartphone-adb.md`. 👤 cần bật Gỡ lỗi không dây và chạy `adb pair`.
  Thêm: đo thời gian Argon2id (E2E1 rủi ro 2) + kiểm giao diện tiếng Anh trên máy thật. 23/11: Phase 1 xong; 24/11:
  Phase 2-3 xong trừ đăng nhập/đồng bộ + TalkBack nghe thật (👤); QA-07..10 đã sửa (PR #41), QA-11 mở. Phase 5: phát
  hành bản sửa (versionCode arm64 = số dựng + 2000, phải > 26114303 đang cài trên máy).
- [ ] 👤 Đăng nhập tsudev: ĐÃ HẾT TẮC (22:20 17/11) - `/auth/web/start` → `/oidc/auth` 303 → `/oidc/interaction/<uid>`
  307 → `tsudev.com/login` 200. Còn nghiệm thu bằng tài khoản tsudev thật của chủ dự án: đăng nhập web
  (sounddb.tsudev.com → Đăng nhập) + app, rồi đồng bộ hai thiết bị. Agent không có tài khoản ⇒ không tự làm được.
- [ ] 👤 Duyệt `xuat-ban` của linux-packages khi có run mới cho 26.11.2301.
- [ ] Phiếu V1 (khuôn phiên bản thống nhất): chờ `tsudev-standards` v3.7.0 ⇒ sync, bản chuyển tiếp phát hành cả
  tên tệp cũ + mới (`{os}-{arch}`, `SHA256SUMS.txt`), phiếu cho scoop-bucket + homebrew-tap. Kế hoạch: phiếu V1 mục 6.
- [ ] winget: PR vào microsoft/winget-pkgs (bộ phân loại từng chặn - để chủ dự án)

## Đang thực hiện

| Task | Agent | Bắt đầu |
| --- | --- | --- |

## Đã hoàn thành (mới nhất trên cùng)

- 25/11/2026 trưa - `sound-db-ff`: **Nghiệm thu 26.11.2501** trên SM-M325FV (SHA256 + 2 chứng thực, cài đè giữ Lịch sử
  2/2, Cài đặt 26.11.2501; `cpu_rate` release Đo mức 29-31). **QA-11 bước 4** (PR #68): lọc A/C/Z theo khối trùng bit,
  `RealFft` cho phổ + NSDF, phân vị một lượt, `instantDb` ⇒ bench x86 189 ⇒ 72 ms/giây âm; máy thật profile Đo mức
  34-38 ⇒ 31-32, Bộ chỉnh âm 72-77 ⇒ 59-65 (CHƯA < 30). **Scorecard Signed-Releases** (PR #69): `release.yml` đính
  `sound-db_<v>.intoto.jsonl`; đã đính bù cho Release 26.11.2501 (kiểm ngoại tuyến `--bundle` đạt). **UI2 + chuẩn
  v6.0.0** (PR #70, production run 45551877260): nền Sáng giấy, preload font + dự phòng đo khớp (CLS 0,049 ⇒ 0,0001,
  LCP 1876 ⇒ 1108 ms), bảng `/en/tai-ve/` 360 px, lưới thẻ 3 × 3, hoạ tiết tĩnh, quét production 96/96 đạt.
  **SignPath** đo 0/6 ⇒ không nộp (phiếu 20261113-02 mục 7). V1: scoop 26.11.1705, cask 26.11.2401, vẫn tên cũ.

- 25/11/2026 sáng - `sound-db-9d`: **QA-11 bước 3** (PR #62): hồ sơ CPU Dart máy thật qua VM service ⇒ dựng/vẽ 51 %,
  FFT phổ thừa 18 % ⇒ phổ chỉ tính đủ nhịp khi Phân tích hiển thị, Đo mức dựng theo phần (`select:`), lưới đồ thị tĩnh,
  số đo 10 Hz ⇒ Đo mức 72-83 ⇒ **32-38** jiffies/s (CHƯA < 30), Cài đặt 15. **SEC2** (PR #63): `/security/` + `/en/`
  (SSL Labs A+ 4/4, Observatory A+ 140, Scorecard 6.3, BP 100 %, PVR bật), `security.txt` mailto security@, cổng
  check-dist; production kiểm bằng nội dung. **Bản 26.11.2501** (PR #64, run 45510603646 đạt; SHA256 + 2 chứng thực +
  VirusTotal 0/10 tệp; cài đè máy thật CHƯA - adb rớt). Dependabot #57, #58 merge (0 check không đạt).

- 25/11/2026 rạng sáng - `sound-db-56` (máy thật SM-M325FV): **26.11.2401 nghiệm thu** - SHA256 + `gh attestation verify`
  đạt, cài đè gói chính giữ Lịch sử 2/2, Cài đặt hiện 26.11.2401. **QA-11**: đo theo luồng thấy chi phí chính là trang
  ẩn của IndexedStack dựng lại 20 lần/giây ⇒ `VisibleListenableBuilder` (PR #60): Cài đặt 88-92 ⇒ 18-19 jiffies/s, tab
  đang đo 88-93 ⇒ 69-76. Test trùng bit DSP (PR #59). Script đo `scripts/android/qa11-cpu.sh` + `thr.sh`. Nhận phiếu SEC2.

- 24/11/2026 tối - `sound-db-56` (tiếp `sound-db-f9`/`sound-db-10` bị tắt đột ngột): **Bản 26.11.2401** (PR #53, Release
  run 45409204596 đạt, Latest). **QA-11** (PR #54): hồ sơ CPU `packages/dsp-dart/tool/bench.dart` - `bandLevels` 51 %,
  dò cao độ 22 %; lập sẵn bảng dải octave + trọng số (126 762 giá trị trùng bit, `vectors.json` không đổi) + chỉ dò cao độ
  khi Bộ chỉnh âm hiển thị (`TickerMode` cho trang ẩn của IndexedStack) ⇒ x86 giảm ~75 %; còn đo máy thật. **Dependabot**
  npm bỏ qua TS ≥ 7, vitest ≥ 5 (PR #55). App 73 test.

- 24/11/2026 chiều - `sound-db-c9` (phiếu điều phối `20261124-QR1` bản sao repo, `-LG2`): **UI1** biểu tượng thanh điều
  hướng 1,19:1 → 4,45:1 (Sáng) / 1,21 → 6,21 (Tối), dùng `TsuNavTheme` của `tsudev_ui` v0.3.0, test đo tương phản (PR #44,
  #47). **Chuẩn v5.1.0** + cổng CI: `--fatal-infos`, cây sạch sau dựng, ngân sách JS web ≤ 170 KB (6,0 KB), APK ≤ 25 MB
  (21,6/23,1 MB) (PR #44); **knip** 6.44.2 + **cargo-machete** 0.9.2, xoá 2 mã chết (PR #46). **LG2** logo vector xoá nền,
  `favicon.svg`, icon hệ điều hành dựng từ SVG (hết nợ crop 704 px) + dấu hiệu TsuDEV trước liên kết tsudev.com (web +
  app); production đã deploy, ảnh Edge Sáng/Tối (PR #45). **QR3** đăng nhập QR vai thiết bị mới + `TsuSignInScreen`
  (PR #51, ADR-0008) sau khi tsudev mở khoá; E2E máy thật chờ 👤. **Sự cố 24/11 17:45**: vòng chờ CI ghi CỨNG số PR nên
  merge NHẦM Dependabot #48 (TS 7 + vitest 5, job web đỏ) ⇒ main đỏ; Deploy hỏng ở bước test TRƯỚC khi triển khai
  (production không đổi, đã kiểm). Revert PR #50 ⇒ CI + Deploy xanh (fe62191). Từ nay chờ/merge theo TÊN NHÁNH lấy từ
  `gh pr create`, chỉ merge khi 0 check không đạt.

- 24/11/2026 - `sound-db-c9` (PR #41): **SEC1 đóng**. **Tìm/lọc Lịch sử** app + web (không dấu, khoảng thời gian, DB v3 +
  migration 0003 `search_norm`; lệch chuẩn ghi AGENTS B.4). **QA-06 đóng, không đổi offset** (Chrome thu nguồn `MIC` nhạy
  hơn `UNPROCESSED` ~45-50 dB, một máy, không máy đo chuẩn). Phiếu 06 phần "CHƯA": sửa **QA-07** (Lịch sử không tự cập
  nhật), **QA-08** (chữ 2.0 + bàn phím: kết quả 0 px), **QA-09** (Máy phát ra nền lệch trạng thái), **QA-10** (nút Mở cài
  đặt khi từ chối quyền - đã thử trên máy); mở **QA-11** (đo dùng ~0,9 lõi CPU - DSP trên luồng chính); đo 24 phút RAM
  phẳng 187 MB; ĐẠT: Bộ chỉnh âm 440,0 Hz/0 cent, 360×640 dp, Cài đặt (Tối, ngoại tuyến, hiệu chuẩn), quyền
  "không hỏi lại" không crash. TalkBack thật cần 👤 nghe. SDB-V1: ba repo CHƯA chuyển; excavator scoop-bucket đỏ vì
  `tsudev-contact` (hash 404) ⇒ Scoop kẹt 26.11.1705.
  **Production đã deploy** (run 45325031102, migration 0003 ✅, phiên bản Worker 204c9fa7): lần đầu hỏng `7403` vì token
  Cloudflare cũ hết quyền ⇒ chủ dự án tạo token mới (thêm D1 Edit), nhận qua `tsu-nhan-bi-mat`; nghiệm thu DEPLOYMENT mục 3 đạt.

- 23/11/2026 - `sound-db-38`: **Bản 26.11.2302** (Latest, PR #39, run 45212957432 mọi job đạt gồm VirusTotal): QA-03,
  QA-04, QA-05. `sha256sum -c SHA256SUMS.txt` + `gh attestation verify` APK arm64 đạt. Tên cũ + chuẩn song song.

- 23/11/2026 - `sound-db-38`: **Kiểm thử máy thật Samsung SM-M325FV** (phiếu 06, PR #38): cài đè 26.11.2301 đạt (SHA256 +
  chứng thực, Lịch sử 0/0 → 2/2 giữ dữ liệu 21/11); Phase 1 số đo khởi động lạnh/RAM/nhịp vẽ/FrameTiming; âm chuẩn 1 kHz
  app đọc 1000,0 Hz; 1200 bản ghi đạt; Phase 3 backup/logcat/chết tiến trình đạt. Sửa **QA-03** (Tiếp tục xoá phiên),
  **QA-04** (Ticker ⇒ Timer, 80 → 20 khung/giây, build p99 60 → 3 ms), **QA-05** (vùng live chỉ báo vùng mức); mở
  **QA-06**. Bộ đo `integration_test` (hiệu năng, quy mô Lịch sử), bản profile `.profile` cài song song. SDB-V1: ba repo
  chưa chuyển tên tệp.

- 23/11/2026 - `sound-db-98`: **Bản 26.11.2301** (Latest, PR #36): QA-01 + QA-02, bản sắc v5.0.0; 5 nền tảng đạt,
  VirusTotal 0/73 mọi tệp, `sha256sum -c SHA256SUMS.txt` + `gh attestation verify` đạt; lần đầu phát hành thêm tên
  tệp chuẩn `{os}-{arch}` + `SHA256SUMS.txt` (phiếu V1 bước 2). **STD50 xong**: PR #34 (sync `.standards` v5.0.0,
  `data-product="sounddb"`, màu xanh vàng chanh, Space Grotesk, `--radius-control`) + PR #35 (trang chủ bố cục
  `do-luong` mặt đồng hồ trung tâm, hoạ tiết `song-am`, og-image mới, app `LevelDial`). Production đã deploy (đo:
  `data-product="sounddb"`, /tai-ve/ hiện 26.11.2301). PR #33 ghi kết quả QA 21/11 + AV1 đóng. adb: không có thiết bị.

- 21/11/2026 - Kiểm thử máy thật Samsung SM-M325FV qua adb (phiếu 06 Phase 1-2 một phần, phiên bị cắt ngang - kết quả
  ghi lại 23/11 ở phiếu 06 mục 6): **QA-01** Lịch sử trống vì SQLite máy không có JSON1 (PR #30), **QA-02** dải 1/3
  octave dưới 10 Hz (PR #31). **TR1-b**: hồ sơ OpenSSF Best Practices 16974, CONTRIBUTING tiếng Anh, fuzz lõi DSP (PR #32).
  AV1: VirusTotal 22/11 v26.11.1705 sạch 0/74 (`docs/store/antivirus.md`).

- 20/11/2026 - `sound-db-32`: **Đổi tên miền sang sound.tsudev.com** (ADR-0007, PR #24 bước A + #25 bước B, theo yêu cầu
  chủ dự án): một Worker gắn hai tên miền; sounddb.tsudev.com giữ VĨNH VIỄN (API cho app đã cài, `/auth/*` 307 về tên
  mới, trang tự chuyển qua `theme.js` + canonical); token nhận `iss` của cả hai tên; tsudev đã thêm callback mới (SDB2,
  đo 303). Loại `run_worker_first: true` (thử thật: mất `_headers`). Phiếu SDB1 sang tsusync (PR tsusync #7). GP1 2.1:
  kiểm mã micro đạt. adb: không có thiết bị.

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
- 20/11/2026 - Tên miền chuẩn sound.tsudev.com, tên cũ giữ vĩnh viễn: `docs/adr/0007-*`
- 24/11/2026 - Đăng nhập QR: app chỉ làm vai thiết bị mới qua trình duyệt hệ thống, giữ ADR-0003: `docs/adr/0008-*`
- 17/11/2026 - Dùng logo tsudev chung cho tới khi có logo riêng được duyệt.

## Sự cố bảo mật

- (chưa có)
