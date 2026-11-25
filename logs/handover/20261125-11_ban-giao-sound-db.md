# PHIẾU BÀN GIAO 20261125-11 - sound-db, cuối phiên `sound-db-ff` (25/11/2026)

- **Từ**: agent-sound phiên `sound-db-ff` - **Đến**: phiên agent-sound kế tiếp (+ 👤 chủ dự án ở mục 4)
- **Thời điểm**: trưa 25/11/2026 - **Trạng thái**: MỞ - **Thay phiếu**: `20261125-10` (mục 3 bẫy của 10 + mục 5 của 09
  vẫn áp dụng)
- **Git**: `main` sạch sau PR tài liệu của phiếu này; `logs/LOCKS.md` trống; chuẩn **v6.0.0**.
- **Máy thật**: SM-M325FV `RF8T80J6WVF` ĐANG CẮM (adb.exe thấy máy). Gói chính = **26.11.2501** (26114501), gói
  `.profile` = 26112506 (QA-11 bước 4 vòng 2).
- **AKB**: `SES-20261125-0952-8465`; bài học `LES-20261125-1035-44cb` (FFT thực, lọc theo khối, không stash khi gradle
  dựng), `LES-20261125-1143-cac4` (đo font dự phòng, quét UI2).

## 1. Đã xong trong phiên `sound-db-ff`

| Việc | PR | Bằng chứng |
| --- | --- | --- |
| P1 nghiệm thu 26.11.2501 trên máy thật | #68 (phiếu 06) | `sha256sum -c` OK; 2 chứng thực `release.yml@refs/tags/v26.11.2501`; `install -r` 26114401 ⇒ 26114501, Lịch sử 2/2, Cài đặt "Phiên bản 26.11.2501"; `cpu_rate` release Đo mức 29/31, Phân tích 78/72, Bộ chỉnh âm 74/66, Cài đặt 13/16 |
| P2 QA-11 bước 4: lọc A/C/Z theo khối (TRÙNG BIT), `RealFft` (phổ + NSDF), phân vị một lượt, `instantDb`, vòng FFT đọc hệ số xoay một lần | #68 | test `qa11_block_rfft_test.dart` (DSP 26 test), app 79 test, Rust + `vectors.json` không đổi; bench x86 189 ⇒ 72 ms/giây âm; máy thật profile Đo mức 34-38 ⇒ **31-32** (4 lượt), Phân tích 82-86 ⇒ 72-74, Bộ chỉnh âm 72-77 ⇒ 59-65; luồng chính 19,7 ⇒ 15,2 |
| Scorecard Signed-Releases: đính gói chứng thực `.intoto.jsonl` vào Release | #69 + đính bù 26.11.2501 | `gh attestation verify <apk> --bundle sound-db_26.11.2501.intoto.jsonl` đạt |
| P3 UI2 + sync chuẩn v6.0.0 | #70, Deploy run 45551877260 | phiếu `20261125-UI2_*` Kết quả: CLS 0,049 ⇒ 0,0001, LCP 1876 ⇒ 1108 ms, production 96/96 lượt quét đạt |
| P4.6 SignPath: đo 6 tín hiệu | - | **0/6** ⇒ KHÔNG nộp; dòng sound-db ở phiếu `~/projects/logs/handover/20261113-02_*` mục 7 |
| V1: kiểm ba repo gói | - | scoop `tsudev-sound-db.json` 26.11.1705, cask 26.11.2401, vẫn tên cũ ⇒ giữ tên cũ trong `release.yml` |

## 2. Việc còn lại - làm THEO THỨ TỰ

### P1. Việc 👤 có agent hỗ trợ (mỗi mục dừng đúng bước cần 👤, nhắn MỘT lần)

1. **Required reviewers** cho Environment `release` + `production`: repo có `admin: true`, id `291851597` = `tsudev-tsudev`
   (đã kiểm). Lệnh PUT bị **bộ phân loại auto mode của Claude Code chặn** (25/11, "Destructive or Unwanted Actions") ⇒
   KHÔNG lách; 👤 tự chạy (dán vào ô lệnh với tiền tố `!`) hoặc cho phép rồi agent chạy:
   ```bash
   for e in release production; do
     echo '{"reviewers":[{"type":"User","id":291851597}]}' | gh api -X PUT repos/tsudev-org/sound-db/environments/$e --input -
   done
   ```
   Sau khi bật: MỖI Deploy/Release chờ 👤 bấm duyệt ⇒ ghi vào AGENTS.md B.5.
2. **Worktree `~/projects/sound-db-qa11`** (nhánh `fix/qa-11-dsp-cpu`, chỉ có ở máy): CÒN thay đổi chưa commit - 4 tệp sửa
   (`tuner_tab.dart`, `measurement.dart`, `locale_test.dart`, `spectrum.dart`) + chưa theo dõi (`qa11_pitch_demand_test.dart`,
   `test/support/`, `qa11_band_cost_test.dart`, `packages/dsp-dart/tool/`). Trông như bản nháp của PR #54 (đã merge) ⇒
   theo phiếu 10 P4.1 phải HỎI 👤 trước khi gỡ. Đồng ý ⇒ `git -C ~/projects/sound-db-qa11 diff > <scratchpad>/qa11.patch`
   (giữ bản sao) rồi `git worktree remove --force ~/projects/sound-db-qa11 && git branch -D fix/qa-11-dsp-cpu`.
3. **Pro nghiệm thu**, **QR3 E2E**, **TalkBack nghe thật**: như phiếu 10 P4.3-P4.5 (nguyên văn còn đúng; máy đang cắm).

### P2. QA-11 - quyết định

Bản release 26.11.2501 (có #62, CHƯA có #68) đã 29-31 ở Đo mức. Bước 4 hạ thêm ~10 % (bản profile 31-32). Phần còn
lại: FFT tích luỹ 1/3 octave 5 lần/giây (~20 % Dart), lọc + tách sóng theo mẫu (~21 %, việc tối thiểu), raster 10 Hz.
Đề xuất 👤 chấp nhận và đóng QA-11 (ISS-20261124-1053-b6ef) sau khi đo bản release kế tiếp; muốn < 30 ở bản profile ⇒
tích luỹ 1/3 octave bằng dàn lọc hạ mẫu (đổi thuật toán: Rust + `vectors.json` + Dart CÙNG PR).

### P3. Phát hành bản kế tiếp

Có QA-11 bước 4 + nền Sáng mới (app đọc token lúc dựng) + `.intoto.jsonl` tự đính. `--build-number` thử tại máy = ĐÚNG
versionCode sắp phát hành (AGENTS B.5). Sau phát hành: nghiệm thu trên máy (cài đè gói chính) + `cpu_rate` release.

### P4. Hàng đợi STATE

ADR-0006/tsusync (👤 duyệt), GP1 Play Console, Play Billing (chờ tsudev B2), V1 bước 3-4 (chờ ba repo gói),
`NSMicrophoneUsageDescription` tiếng Anh (macOS), winget, DK2 (chỉ kiểm trạng thái), Scorecard: Branch-Protection 3/10,
Code-Review 0 (một người, không tự duyệt được), Fuzzing 0 (Rust fuzz hiện có không được Scorecard nhận - cần
ClusterFuzzLite nếu muốn).

## 3. Bẫy mới

- **KHÔNG `git stash`/`checkout` khi `flutter build` đang chạy nền** - bước biên dịch Dart có thể đọc cây đã stash; kiểm
  APK bằng hồ sơ CPU (hàm mới phải có mặt). Phiên này may mắn: hồ sơ có `RealFft.forward`, `_allPercentiles`.
- `gh pr checks` không TTY: vòng chờ bằng `grep "\spending\s"` THOÁT SỚM ⇒ dùng `--json bucket --jq
  'map(select(.bucket=="pending"))|length'`.
- `cpu_rate` trên máy nhiễu ±5 (một lượt 45 rồi 31-32) ⇒ đo ≥ 4 lượt trước khi kết luận.
- Cổng quy ước 7.1 bắt ký tự em/en-dash ở MỌI tệp, kể cả regex ⇒ viết `—`.
- knip coi `.standards/templates/**` là mã ⇒ `knip.json` có `"ignore": [".standards/**"]`.
- Đổi cài đặt bảo vệ repo (PUT environments) bị bộ phân loại auto mode chặn - việc 👤.

## 4. Việc của chủ dự án (👤)

- Chạy lệnh Required reviewers (P1.1) hoặc cho phép agent chạy; trả lời có gỡ worktree qa11 không (P1.2).
- Đăng nhập TsuDEV (Pro, QR3), nghe TalkBack và trả lời; quyết định đóng QA-11 ở ~0,3 lõi (P2).

## 5. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán NGUYÊN VĂN)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Trả lời tiếng Việt. Làm ĐÚNG THỨ TỰ, không bỏ bước, không hỏi lại điều đã
có trong phiếu. Mục tiêu: hoàn thành phiếu logs/handover/20261125-11_ban-giao-sound-db.md mục 2 (P1 → P2 → P3 → P4), mỗi
việc có bằng chứng.

0. ỦY QUYỀN SẴN: tạo nhánh, commit, đẩy, mở PR, chờ CI và MERGE PR của chính phiên theo TÊN NHÁNH khi 0 check không đạt;
   cài APK lên điện thoại đang cắm (adb.exe Windows); deploy qua merge main; gắn thẻ phát hành khi phiếu yêu cầu. KHÔNG
   merge PR Dependabot/người khác khi CI chưa xanh; KHÔNG `adb usb`; KHÔNG sửa .standards/; KHÔNG tạo/đổi tên repo;
   KHÔNG git stash/checkout khi flutter build đang chạy.
1. KHỞI ĐỘNG: CLAUDE.md, AGENTS.md (B.3-B.5), logs/STATE.md, logs/LOCKS.md, phiếu 11 TOÀN BỘ, phiếu 10 mục 3 + P4.3-P4.5,
   phiếu 06 mục 6 dòng QA-11. `akb start "sound-db: phiếu 11 - việc 👤 có hỗ trợ, QA-11, phát hành"`; `akb search "QA-11"`.
   `git status`, `gh pr list`, ListAgents, `adb.exe devices -l` (trống ⇒ hỏi tôi cắm máy MỘT lần).
2. GHI KHOÁ (LOCKS + "Đang thực hiện" STATE) trước khi sửa; nhả ngay khi xong từng vùng.
3. P1: hỏi tôi MỘT lần gộp (Required reviewers, gỡ worktree qa11, sẵn sàng đăng nhập Pro/QR3 + nghe TalkBack) rồi làm
   từng mục theo trả lời.
4. P2 QA-11: theo quyết định của tôi (đóng ở ~0,3 lõi hoặc dàn lọc hạ mẫu - Rust + vector + Dart cùng PR).
5. P3 phát hành bản kế tiếp + nghiệm thu trên máy (SHA256, attestation + --bundle .intoto.jsonl, cài đè, cpu_rate).
6. P4 hàng đợi STATE.
7. NGUYÊN TẮC: kết luận có số đo/log; chỉ `dart format -l 120` tệp mình sửa; bí mật chỉ qua tsu-nhan-bi-mat; KHÔNG câu
   "do AI"/"Generated with"/Co-Authored-By; chờ tiến trình nền bằng run_in_background (không vòng echo); lỗi > 10 phút ⇒
   akb new issue, mẹo ⇒ akb new lesson.
8. KẾT THÚC: STATE + phiếu bàn giao mới (khuôn như phiếu 11, có prompt), PR + merge, `akb close` + `akb sync --project
   sound-db`, main sạch, LOCKS trống, dừng tiến trình nền. Báo cáo: xong gì (số đo), còn gì, việc 👤.
```
