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

- Cắm lại cáp USB điện thoại (P1).
- SignPath Foundation: điền đơn + xác nhận email nếu muốn ký mã bản Windows (trang `/security/` đang ghi "chưa có").
- Gỡ worktree `~/projects/sound-db-qa11` khi đồng ý (phiếu 09).
- QR3 E2E, TalkBack nghe thật, DK2, Pro nghiệm thu, Required reviewers - như phiếu 07 mục 3.

## 5. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán NGUYÊN VĂN)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Trả lời tiếng Việt. Làm ĐÚNG THỨ TỰ, không bỏ bước, không hỏi lại điều đã
có trong phiếu. Mục tiêu: hoàn thành phiếu logs/handover/20261125-10_ban-giao-sound-db.md mục 2 (P1 → P2 → P3), mỗi
việc có bằng chứng.

0. ỦY QUYỀN SẴN: tạo nhánh, commit, đẩy, mở PR, chờ CI và MERGE PR của chính phiên theo TÊN NHÁNH khi 0 check không đạt;
   cài APK lên điện thoại đang cắm (adb.exe Windows); deploy qua merge main; gắn thẻ phát hành khi phiếu yêu cầu. KHÔNG
   merge PR Dependabot/người khác khi CI chưa xanh; KHÔNG `adb usb`; KHÔNG sửa .standards/; KHÔNG tạo/đổi tên repo.
1. KHỞI ĐỘNG: CLAUDE.md, AGENTS.md (B.3-B.5), logs/STATE.md, logs/LOCKS.md, phiếu 10 TOÀN BỘ, phiếu 09 mục 3 + 5, phiếu 06
   mục 6 dòng QA-11. `akb start "sound-db: phiếu 10 - nghiệm thu 26.11.2501, QA-11 bước 4, UI2"`; `akb search "QA-11"`.
   `git status`, `gh pr list`, ListAgents, `adb.exe devices -l` (trống ⇒ hỏi tôi cắm máy MỘT lần, trong lúc chờ làm P2).
2. GHI KHOÁ (LOCKS + "Đang thực hiện" STATE) trước khi sửa; nhả ngay khi xong từng vùng.
3. P1 nghiệm thu 26.11.2501 (SHA256 + attestation + cài đè giữ dữ liệu + cpu_rate bản release).
4. P2 QA-11 bước 4: hồ sơ trước (qa11-profile.sh) ⇒ test đỏ ⇒ sửa (Rust + vectors.json + Dart cùng PR) ⇒ xanh ⇒ profile
   --build-number ≥ 26112505 ⇒ qa11-cpu.sh ⇒ bảng trước/sau ở phiếu 06. Chưa đạt sau 2 vòng ⇒ ghi số thật, KHÔNG nói "đạt".
5. P3 UI2 theo phiếu 20261125-UI2 (đọc phiếu gốc mục 0), rồi hàng đợi STATE.
6. NGUYÊN TẮC: kết luận có số đo/log; widget nghe MeasurementController dùng VisibleListenableBuilder (+ select khi chỉ
   hiển thị vài số); chỉ `dart format -l 120` tệp mình sửa; bí mật chỉ qua tsu-nhan-bi-mat; KHÔNG câu "do AI"/"Generated
   with"/Co-Authored-By; lỗi > 10 phút ⇒ akb new issue, mẹo ⇒ akb new lesson.
7. PR/CI: mỗi vùng một PR; chạy cổng tại máy (flutter analyze --fatal-infos + flutter test; dart test DSP; npm test &&
   npm run build) trước khi đẩy; chờ CI bằng `gh pr checks <nhánh>` chạy nền; job macOS huỷ 0 bước ⇒ `gh run rerun --failed`.
8. KẾT THÚC: phiếu 06 + STATE + phiếu bàn giao mới (khuôn như phiếu 10, có prompt), PR + merge, `akb close` + `akb sync
   --project sound-db`, main sạch, LOCKS trống, dừng tiến trình nền. Báo cáo: xong gì (số đo), còn gì, việc 👤.
```
