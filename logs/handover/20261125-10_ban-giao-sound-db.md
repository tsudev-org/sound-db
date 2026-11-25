# PHIẾU BÀN GIAO 20261125-10 - sound-db, cuối phiên `sound-db-9d` (25/11/2026)

- **Từ**: agent-sound phiên `sound-db-9d` - **Đến**: phiên agent-sound kế tiếp (+ 👤 chủ dự án ở mục 4)
- **Thời điểm**: sáng 25/11/2026 - **Trạng thái**: MỞ - **Thay phiếu**: `20261125-09` (mục 3 công cụ đo + mục 5 bẫy của 09,
  mục 4 của 07 + 08 vẫn áp dụng)
- **Git**: `main` sạch sau PR tài liệu của phiếu này; `logs/LOCKS.md` trống; không nhánh dở của phiên.
- **Máy thật**: SM-M325FV `RF8T80J6WVF` - **cáp/adb RỚT sau 02:20** (adb.exe `devices` trống từ 06:00). Gói `.profile` trên
  máy = 26112504 (vòng 2 QA-11). Gói chính vẫn **26.11.2401** (26114401) - CHƯA cài đè 26.11.2501.
- **AKB**: `SES-20261125-0127-ab50`.
- **Phiếu mới chưa làm**: `logs/handover/20261125-UI2_ra-soat-giao-dien-web.md` (rà giao diện web bằng trình duyệt + hiện
  đại hoá, phát bởi `tsudev-3e`; đọc phiếu gốc `~/projects/logs/handover/20261125-UI2_*-toan-he.md` mục 0 trước).

## 1. Đã xong trong phiên `sound-db-9d`

| Việc | PR | Bằng chứng |
| --- | --- | --- |
| QA-11 bước 3: phổ chỉ tính đủ nhịp khi Phân tích hiển thị; Đo mức dựng lại theo phần (`select:`); lưới đồ thị tĩnh; số đo 10 lần/giây | #62 | máy thật Đo mức **72-83 ⇒ 32-38** jiffies/s; test `meter_tick_cost_test.dart` đỏ ⇒ xanh; app 79 test |
| Công cụ hồ sơ CPU Dart qua VM service (bằng DevTools CPU Profiler) | #62 | `scripts/android/cpu-profile.mjs`, `qa11-profile.sh` |
| SEC2 trang `/security/` + `/en/security/`, `security.txt` mailto security@, `docs/security/trust.json`, cổng check-dist | #63 | production: `curl … /security/ \| grep "Báo lỗ hổng"` có; SSL Labs A+ 4/4, Observatory A+ 140, Scorecard 6.3, BP 100 % |
| Phát hành **26.11.2501** | #64, thẻ `v26.11.2501` | run 45510603646 mọi job đạt; `sha256sum -c` OK (APK arm64 23,0 MiB, x64 24,5 MiB ≤ 25); `gh attestation verify` 2 chứng thực `release.yml@refs/tags/v26.11.2501`; VirusTotal 0 cờ 10/10 tệp; Latest; ghi chú vi + en |
| Dependabot actions (4 cập nhật), npm (6 cập nhật, TS 6.0.3) | #57, #58 | mọi check đạt (#58: job macOS huỷ 0 bước ⇒ `rerun --failed` ⇒ đạt) |

**QA-11 CHƯA ĐẠT** (< 30 ở Đo mức): bảng số đủ ở phiếu 06 mục 6. Sau vòng 1: luồng chính 19,7, raster 11,6, thu âm 4,0;
Dart còn lại: FFT tích luỹ 1/3 octave 21 %, lọc A/C/Z theo mẫu 22 %, khung vẽ 27 %. Vòng 2 (10 Hz) không đổi số đo ⇒
khâu còn lại là DSP theo mẫu + FFT, không phải tần suất khung.

## 2. Việc còn lại - làm THEO THỨ TỰ (mỗi mục một PR)

### P1. Nghiệm thu 26.11.2501 trên máy thật (cần 👤 cắm lại cáp)

`adb.exe devices -l` thấy máy ⇒ tải `sound-db_26.11.2501_android-arm64.apk` + `SHA256SUMS.txt` ⇒ `sha256sum -c
SHA256SUMS.txt --ignore-missing` + `gh attestation verify <apk> --repo tsudev-org/sound-db` ⇒ `adb install -r` đè gói chính
(giữ Lịch sử 2/2, Cài đặt hiện 26.11.2501) ⇒ `cpu_rate` bản release ở Đo mức (đổi `PKG=com.tsudev.sounddb` trong
`qa11-cpu.sh` hoặc đặt biến) ⇒ ghi phiếu 06 mục 6.

### P2. QA-11 bước 4 (đổi DSP - Rust + `conformance/vectors.json` + Dart CÙNG PR, AGENTS B.3)

Theo hồ sơ (phiếu 06 mục 6): (a) lọc trọng số A/C/Z theo khối (Float64List, vòng lặp không cấp phát) - kiểm trùng bit với
Rust trước; (b) FFT thực N/2 phức cho phổ; (c) tích luỹ 1/3 octave cho phiên bằng cách khác FFT 5 lần/giây. Đo bằng
`qa11-profile.sh` TRƯỚC và SAU mỗi bước. Mục tiêu < 30 jiffies/s ở Đo mức.

### P3. UI2 (phiếu `20261125-UI2_*`), rồi hàng đợi STATE

tsudev-standards **v6.0.0** đã phát hành (MAJOR: bảng Sáng "giấy" xám-xanh, đổi 10 token màu Sáng) - sync theo Hướng
dẫn nâng cấp trong CHANGELOG của chuẩn, sinh lại `tokens/` bằng `scripts/build-tokens.mjs`, làm cùng phase giao diện UI2.

Kiểm main xanh sau #58 (TS 6.0.3, knip 6.47, wrangler 4.166). V1 bước 3-4, ADR-0006/tsusync (👤), GP1, Play Billing, winget - như `logs/STATE.md`.

### P4. Việc trước đây của 👤 - chủ dự án GIAO cho phiên sau làm (25/11/2026), làm sau P1-P3 hoặc xen khi chờ CI

Nguyên tắc: agent làm mọi bước kỹ thuật; chỗ cần đăng nhập/mật khẩu/OTP/nghe bằng tai thì dừng đúng bước đó, nhắn chủ
dự án MỘT lần với hướng dẫn ngắn, chờ trả lời rồi làm tiếp. Mỗi mục ghi kết quả + bằng chứng vào phiếu 06 hoặc STATE.

1. **Gỡ worktree `~/projects/sound-db-qa11`** - chủ dự án ĐÃ ĐỒNG Ý (25/11). Trước khi gỡ: `git -C ~/projects/sound-db-qa11
   status --short` (có thay đổi chưa commit ⇒ ghi lại danh sách, KHÔNG gỡ, hỏi). Sạch ⇒ `git worktree remove
   ~/projects/sound-db-qa11 && git branch -D fix/qa-11-dsp-cpu`; nhánh đã đẩy lên remote thì giữ nhánh remote.
2. **Required reviewers** cho Environment `release` + `production`: đo 25/11 `gh api repos/tsudev-org/sound-db -q
   .permissions` ⇒ `admin: true` (trước đây 403) ⇒ agent tự làm:
   ```bash
   for e in release production; do
     echo '{"reviewers":[{"type":"User","id":291851597}]}' | gh api -X PUT repos/tsudev-org/sound-db/environments/$e --input -
   done
   gh api repos/tsudev-org/sound-db/environments -q '.environments[]|.name+" "+([.protection_rules[]?.type]|join(","))'
   ```
   Kiểm id 291851597 đúng tài khoản chủ dự án (`gh api user/291851597 -q .login` hoặc `gh api users/tsudev-tsudev -q .id`).
   Hệ quả: từ đó MỖI lượt Deploy/Release chờ chủ dự án bấm duyệt (agent không tự duyệt) - ghi vào AGENTS.md B.5 + nhắn
   chủ dự án. Còn 403 ⇒ ghi lại, giữ là việc 👤.
3. **Nghiệm thu Pro bằng tài khoản thật** (STATE, phiếu PRO2 mục 5): agent mở `https://sound.tsudev.com/bang-dieu-khien/`
   trên Edge (hồ sơ chủ dự án, KHÔNG dùng `tsudev-bp` nếu phiên khác đang giữ) ⇒ 👤 đăng nhập TsuDEV ⇒ trang Tài khoản phải
   hiện "Bản miễn phí" hoặc "TsuDEV Pro tới …". Đồng thời `wrangler tail` (không in token/cookie) không có
   `entitlements_unavailable`; D1 bảng `entitlements` có dòng mới. Pro ⇒ thử đồng bộ một phiên đo từ app lên và thấy ở web.
4. **QR3 E2E** (ADR-0008) - cần máy cắm: app 26.11.2501 ⇒ Cài đặt ⇒ Đăng nhập ⇒ "Quét để đăng nhập"; 👤 mở tsudev.com
   trên máy tính đã đăng nhập ⇒ Tài khoản ⇒ Đăng nhập trên điện thoại ⇒ đưa mã QR trước camera. Agent chụp màn hình app
   trước/sau (`shot`, chỉ khi app ở trước), kiểm app hiện đã đăng nhập + `logcat` không lỗi/không lộ token. Máy cần Google
   Play Services (ML Kit unbundled).
5. **TalkBack nghe thật** (QA-05) - cần máy cắm: agent ghi giá trị cũ `settings get secure
   enabled_accessibility_services` + `accessibility_enabled`, bật TalkBack, mở Đo mức, bấm Bắt đầu đo (toạ độ 867,156) ⇒
   👤 vuốt qua màn Đo mức ~30 s và trả lời: có đọc DỒN số đo không, có đọc vùng mức khi đổi không ⇒ agent TẮT TalkBack ngay,
   khôi phục giá trị cũ, ghi kết quả QA-05 vào phiếu 06.
6. **Ký mã Windows - SignPath Foundation** - chủ dự án XÁC NHẬN 25/11/2026: giữ đúng quy định phiếu 20261113-02, KHÔNG
   nộp vội, không hỏi lại. CẨN THẬN: SignPath đã TỪ CHỐI hệ ngày 12/11/2026; phiếu toàn hệ
   `~/projects/logs/handover/20261113-02_ke-hoach-uy-tin-he-sinh-thai.md` mục 5 quy định chỉ nộp lại cho MỘT dự án (đề
   xuất Lotus Share) khi đạt ≥ 4/6 tín hiệu; nộp sai lúc có thể hỏng hồ sơ VĨNH VIỄN. Việc của phiên: đo 6 tín hiệu cho
   sound-db (sao/fork, người đóng góp ngoài, bài viết độc lập, số tháng phát hành đều + ghi chú tiếng Anh, Scorecard
   hiện 6.3 / BP passing, lượt tải Release) ⇒ ghi bảng vào phiếu 06 hoặc STATE + mục 7 phiếu 20261113-02 (chỉ dòng
   sound-db). Đạt ≥ 4/6 VÀ phiếu toàn hệ chọn sound-db ⇒ điền đơn trên Edge `tsudev-bp` (một phiên một lúc, đóng Edge khi
   xong), 👤 xác nhận email. Chưa đạt ⇒ KHÔNG nộp, giữ dòng "Chưa có" trên `/security/` (lý do đúng sự thật) và báo chủ
   dự án số đo + điều kiện còn thiếu. Việc nâng Scorecard ≥ 7 làm được ngay trong repo (đọc các check điểm thấp ở
   `https://api.securityscorecards.dev/projects/github.com/tsudev-org/sound-db`) - mỗi sửa một PR.
7. Còn lại như STATE: DK2 (chờ duyệt nhãn tín nhiệm - chỉ kiểm trạng thái), GP1 Google Play Console (👤 đăng nhập Play
   Console, agent soạn nội dung), V1 bước 3-4, ADR-0006/tsusync (👤 duyệt), Play Billing (chờ tsudev B2),
   `NSMicrophoneUsageDescription` tiếng Anh (cần macOS), winget.

## 3. Bẫy mới (bổ sung phiếu 09 mục 5)

- Bản profile TẮT bộ lấy mẫu CPU tới khi client bật: `getCpuSamples` trả "Profiler is disabled" ⇒ gọi `setFlag profiler
  true` trước (đã có trong `cpu-profile.mjs`).
- `cpu_rate` là CPU của CẢ tiến trình: chuyển DSP sang isolate KHÔNG giảm số này (chỉ dời luồng). Muốn giảm phải bớt việc.
- Giảm tần suất khung (20 ⇒ 10 Hz) không đổi số đo khi phần còn lại là DSP theo mẫu - đo trước khi làm tiếp.
- knip coi tệp `.mjs` chỉ được gọi từ script shell là "Unused files" ⇒ thêm vào `entry` của `knip.json`.
- `check-dist` so ngày đo `trust.json` (giờ VN) với `Date.now()` (UTC): đã cho dư 1 ngày.
- SSL Labs + Observatory đo được bằng API (`api.ssllabs.com/api/v3/analyze?publish=off`, Observatory v2 POST) - không cần
  Edge `tsudev-bp`.

## 4. Việc của chủ dự án (👤)

- Cắm cáp USB điện thoại (P1, P4.4, P4.5); không đóng app Sound Db từ màn Gần đây khi đang đo.
- Chỉ phần không uỷ quyền được: đăng nhập TsuDEV (P4.3, P4.4), nghe TalkBack và trả lời (P4.5), xác nhận email SignPath
  nếu đủ điều kiện nộp (P4.6), bấm duyệt Deploy/Release sau khi bật Required reviewers (P4.2).

## 5. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán NGUYÊN VĂN)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Trả lời tiếng Việt. Làm ĐÚNG THỨ TỰ, không bỏ bước, không hỏi lại điều đã
có trong phiếu. Mục tiêu: hoàn thành phiếu logs/handover/20261125-10_ban-giao-sound-db.md mục 2 (P1 → P2 → P3 → P4), mỗi
việc có bằng chứng.

0. ỦY QUYỀN SẴN: gỡ worktree ~/projects/sound-db-qa11 + nhánh fix/qa-11-dsp-cpu (khi sạch); bật Required reviewers;
   tạo nhánh, commit, đẩy, mở PR, chờ CI và MERGE PR của chính phiên theo TÊN NHÁNH khi 0 check không đạt;
   cài APK lên điện thoại đang cắm (adb.exe Windows); deploy qua merge main; gắn thẻ phát hành khi phiếu yêu cầu. KHÔNG
   merge PR Dependabot/người khác khi CI chưa xanh; KHÔNG `adb usb`; KHÔNG sửa .standards/; KHÔNG tạo/đổi tên repo.
1. KHỞI ĐỘNG: CLAUDE.md, AGENTS.md (B.3-B.5), logs/STATE.md, logs/LOCKS.md, phiếu 10 TOÀN BỘ, phiếu 09 mục 3 + 5, phiếu 06
   mục 6 dòng QA-11. `akb start "sound-db: phiếu 10 - nghiệm thu 26.11.2501, QA-11 bước 4, UI2"`; `akb search "QA-11"`.
   `git status`, `gh pr list`, ListAgents, `adb.exe devices -l` (trống ⇒ hỏi tôi cắm máy MỘT lần, trong lúc chờ làm P2).
2. GHI KHOÁ (LOCKS + "Đang thực hiện" STATE) trước khi sửa; nhả ngay khi xong từng vùng.
3. P1 nghiệm thu 26.11.2501 (SHA256 + attestation + cài đè giữ dữ liệu + cpu_rate bản release).
4. P2 QA-11 bước 4: hồ sơ trước (qa11-profile.sh) ⇒ test đỏ ⇒ sửa (Rust + vectors.json + Dart cùng PR) ⇒ xanh ⇒ profile
   --build-number ≥ 26112505 ⇒ qa11-cpu.sh ⇒ bảng trước/sau ở phiếu 06. Chưa đạt sau 2 vòng ⇒ ghi số thật, KHÔNG nói "đạt".
5. P3 UI2 theo phiếu 20261125-UI2 (đọc phiếu gốc mục 0).
5b. P4 (việc trước đây của 👤, chủ dự án đã giao): gỡ worktree sound-db-qa11 (đã đồng ý), Required reviewers, nghiệm thu
   Pro, QR3 E2E, TalkBack, SignPath (CHỈ nộp khi đạt điều kiện phiếu 20261113-02 mục 5), rồi hàng đợi STATE. Chỗ cần
   đăng nhập/nghe/OTP ⇒ dừng đúng bước, nhắn tôi MỘT lần kèm hướng dẫn, chờ trả lời rồi làm tiếp.
6. NGUYÊN TẮC: kết luận có số đo/log; widget nghe MeasurementController dùng VisibleListenableBuilder (+ select khi chỉ
   hiển thị vài số); chỉ `dart format -l 120` tệp mình sửa; bí mật chỉ qua tsu-nhan-bi-mat; KHÔNG câu "do AI"/"Generated
   with"/Co-Authored-By; lỗi > 10 phút ⇒ akb new issue, mẹo ⇒ akb new lesson.
7. PR/CI: mỗi vùng một PR; chạy cổng tại máy (flutter analyze --fatal-infos + flutter test; dart test DSP; npm test &&
   npm run build) trước khi đẩy; chờ CI bằng `gh pr checks <nhánh>` chạy nền; job macOS huỷ 0 bước ⇒ `gh run rerun --failed`.
8. KẾT THÚC: phiếu 06 + STATE + phiếu bàn giao mới (khuôn như phiếu 10, có prompt), PR + merge, `akb close` + `akb sync
   --project sound-db`, main sạch, LOCKS trống, dừng tiến trình nền. Báo cáo: xong gì (số đo), còn gì, việc 👤.
```
