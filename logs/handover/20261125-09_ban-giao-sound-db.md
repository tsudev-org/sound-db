# PHIẾU BÀN GIAO 20261125-09 - sound-db, cuối phiên `sound-db-56` (25/11/2026)

- **Từ**: agent-sound phiên `sound-db-56` - **Đến**: phiên agent-sound kế tiếp (+ 👤 chủ dự án ở mục 4)
- **Thời điểm**: rạng sáng 25/11/2026 - **Trạng thái**: MỞ - **Thay phiếu**: `20261124-08` (mục 4 bẫy của 07 + 08 vẫn áp dụng)
- **Git**: `main` sạch sau PR #60 + PR tài liệu của phiếu này; `logs/LOCKS.md` trống; không nhánh dở của phiên.
- **Máy thật**: SM-M325FV `RF8T80J6WVF` cắm USB (adb.exe Windows, đã uỷ quyền). Gói chính `com.tsudev.sounddb` =
  **26.11.2401 chính thức** (versionCode 26114401, dữ liệu thật 2 phiên 21/11). Gói `com.tsudev.sounddb.profile` = bản
  profile từ PR #60 (versionCode 26112502). Bản dựng thử tại máy kế tiếp cho gói CHÍNH phải có versionCode ĐÚNG bằng bản
  sắp phát hành (> 26114401); gói `.profile` chỉ cần ≥ 26112502.
- **AKB**: `SES-20261124-2245-4100` (đã đóng), `SES` của phần rạng sáng 25/11 (xem `akb search "sound-db-56"`),
  `LES-20261124-2302-4693`, `LES` mới về trang ẩn IndexedStack dựng lại theo nhịp.
- **Còn treo, KHÔNG phải của phiên sau tự xử lý**: worktree `~/projects/sound-db-qa11` (nhánh `fix/qa-11-dsp-cpu`, việc dở
  của phiên `sound-db-10`, đã được thay bằng PR #54 + #59) - chỉ gỡ khi chủ dự án đồng ý
  (`git worktree remove ~/projects/sound-db-qa11 && git branch -D fix/qa-11-dsp-cpu`).

## 1. Đã xong trong phiên `sound-db-56`

| Việc | PR | Bằng chứng |
| --- | --- | --- |
| QA-11 bước 1: bảng dải octave + trọng số lập sẵn (trùng bit), chỉ dò cao độ ở Bộ chỉnh âm | #54, #59 | `tool/bench.dart` x86 -75 % DSP; test trùng bit 14 test DSP |
| Dependabot npm bỏ qua TS ≥ 7, vitest/@vitest ≥ 5 | #55 | `.github/dependabot.yml` |
| Nghiệm thu **26.11.2401** trên máy thật | - | `sha256sum -c` + `gh attestation verify` (2 chứng thực, `release.yml@refs/tags/v26.11.2401`); cài đè gói chính giữ Lịch sử 2/2; Cài đặt hiện 26.11.2401; log 0 lỗi |
| QA-11 bước 2: trang ẩn của IndexedStack không dựng lại theo nhịp đo (`VisibleListenableBuilder`) | #60 | máy thật Cài đặt 88-92 ⇒ **18-19** jiffies/s; test `hidden_pages_idle_test.dart` đỏ ⇒ xanh; app 75 test |

Số đo QA-11 máy thật (bản profile, `cpu_rate` 20 s × 2 vòng; 100 = một lõi; chi tiết phiếu 06 mục 6):

| Tab (đang đo) | Trước (26.11.2302) | Sau #54 | Sau #60 |
| --- | --- | --- | --- |
| Đo mức | 90-91 | 77-82 | 73 |
| Phân tích | 93 | 90-91 | 74-76 |
| Bộ chỉnh âm | 88-89 | 80-85 | 69-71 |
| Cài đặt | 88-92 | 74-76 | 18-19 |

Theo luồng (Cài đặt, trước #60): luồng chính 55, `1.raster` 23, `lfbandit.record` 3,6. Bộ đo: mục 3.

## 2. Việc còn lại - làm THEO THỨ TỰ (mỗi mục một PR)

### P1. QA-11 bước 3 - tab đang hiển thị còn ~0,7 lõi (mục tiêu < 30 jiffies/s ở Đo mức)

1. **Hồ sơ trước khi sửa** (bằng chứng, không đoán): `flutter run --profile` gói `.profile` trên máy, DevTools CPU
   profiler 10 s ở tab Đo mức khi đang đo + đo theo luồng (`scripts/android/thr.sh`). Tách: DSP (`Engine.push`, `_onTick`), build/layout
   widget (LevelDial, đồ thị 2 phút `levelHistory` 1200 điểm, `StatGrid`), chuyển byte ⇒ Float32 (`audio_input.dart`
   `_onBytes`), raster.
2. Hướng sửa theo số đo (chọn khâu lớn nhất trước):
   - **DSP sang isolate riêng**: `Engine` sống trong isolate, nhận khối mẫu qua `SendPort` (TransferableTypedData), trả
     ảnh chụp đã tính sẵn mỗi 50 ms. Không đổi thuật toán ⇒ Rust/`vectors.json` không đổi. Giữ API
     `MeasurementController` (test dùng `debugProcess` đồng bộ - cần đường đồng bộ cho test).
   - **Giảm vẽ**: `RepaintBoundary` quanh đồ thị/đồng hồ; đồ thị lịch sử 10 điểm/giây chỉ cần vẽ lại 10 lần/giây; chữ số
     chỉ dựng lại khi giá trị hiển thị (đã làm tròn) đổi.
   - FFT thực (N/2 phức) cho phổ + NSDF: đổi số học ⇒ Rust tham chiếu + `vectors.json` + Dart CÙNG PR (AGENTS B.3) -
     chỉ làm nếu hồ sơ cho thấy FFT vẫn đáng kể.
3. Đo lại bằng `scripts/android/qa11-cpu.sh` (mục 3) - ghi bảng trước/sau vào phiếu 06 mục 6; đạt ⇒ đóng QA-11.
4. Test đỏ ⇒ xanh cho mỗi thay đổi hành vi; bộ test app hiện 75.

### P2. SEC2 - trang `/security` bằng chứng tự kiểm chứng (phiếu `logs/handover/20261125-SEC2_*`, phiếu gốc
`~/projects/logs/handover/20261125-SEC2_trang-security-bang-chung-tin-cay-toan-he.md` mục 0-2 - ĐỌC TRƯỚC)

Hiện trạng đo 25/11 00:20: header production đủ (HSTS preload 2 năm, CSP chặt, nosniff, DENY, Referrer-Policy,
Permissions-Policy, COOP/CORP); `security.txt` có Contact = GitHub advisory, Expires 2027-11-17, `Policy:` trỏ
`/bao-mat/`; `/security/` trả 404; đã có trang `/bao-mat/` (vi) + `/en/bao-mat/`?(kiểm).

1. `apps/web/public/.well-known/security.txt`: thêm `Contact: mailto:security@tsudev.com` (đứng TRƯỚC Contact GitHub),
   `Policy: https://sound.tsudev.com/security/`; test chặn `Expires` hết hạn / > 1 năm (mẫu tsudev `test/securityTxt.test.ts`)
   trong bộ test web.
2. Dữ liệu `docs/security/trust.json` (nguồn chân lý lúc build): E1 BP 16974, E2 Scorecard
   (`https://scorecard.dev/viewer/?uri=github.com/tsudev-org/sound-db` - đọc điểm thật), E3 chữ ký Release
   (`gh attestation verify` + `SHA256SUMS.txt` + VirusTotal ở `docs/store/antivirus.md`), E4 security.txt, E5 SSL Labs,
   E6 Observatory, E7 HSTS preload (do repo tsudev nộp - chỉ ghi header), E8 SignPath: bản Windows có ⇒ kiểm điều kiện,
   chưa đủ ⇒ ghi lý do, E10 SECURITY.md + Private vulnerability reporting (bật chưa? `gh api repos/tsudev-org/sound-db/private-vulnerability-reporting`; bị chặn ⇒ 👤).
   Mỗi mục: trạng thái THẬT + liên kết bên thứ ba + ngày đo; không có liên kết ⇒ không hiện. KHÔNG nhãn trang trí.
3. E5/E6: SSL Labs `https://www.ssllabs.com/ssltest/analyze.html?d=sound.tsudev.com&hideResults=on` (chờ xong, ghi
   điểm); Observatory API v2 `curl -X POST "https://observatory-api.mdn.mozilla.net/api/v2/scan?host=sound.tsudev.com"`
   (ghi grade/score). Cần trình duyệt ⇒ Edge hồ sơ `tsudev-bp` qua CDP theo phiếu gốc mục 0.4 (một phiên một lúc,
   đóng Edge khi xong).
4. Trang: view `src/views/Security.astro` + `src/pages/security.astro` + `src/pages/en/security.astro`; nội dung theo
   mục 2 phiếu gốc (Báo lỗ hổng - security@tsudev.com, advisory, phản hồi 7 ngày; bảng bằng chứng; cách tự kiểm bản tải
   `sha256sum -c SHA256SUMS.txt`, `Get-FileHash`, `gh attestation verify`; mục "Chưa có / không áp dụng" có lý do).
   Chuỗi vi + en ở `src/i18n/{vi,en}.ts`; liên kết từ chân trang cột Pháp lý; `/bao-mat/` giữ (hoặc trỏ sang) - không
   làm gãy liên kết cũ. Sitemap thêm `/security/`. Ngân sách JS ≤ 170 KB, CSP không đổi (không gọi API ngoài lúc xem).
5. Kiểm: `npm test && npm run build` (check-dist), deploy (tự động khi merge main), `curl -s https://sound.tsudev.com/security/ | grep "Báo lỗ hổng"`
   (kiểm bằng NỘI DUNG). Ghi một dòng "Kết quả xử lý" ở phiếu SEC2 bản repo + cập nhật hàng `sound-db` ở bảng mục 3 phiếu
   gốc (chỉ dòng của mình), rồi `SendMessage` cho phiên `tsudev-*` điều phối (ListAgents) báo xong.

### P3. Phát hành bản sửa (sau P1, có thể gộp P2)

`26.11.DDNN` theo ngày phát hành (`.standards/docs/VERSIONING.md`); versionCode arm64 = số dựng + 2000 phải > 26114401.
Ghi chú phát hành vi + en (giảm CPU/pin khi đo), không câu "do AI". Kiểm: CI release (APK ≤ 25 MiB - x64 còn ~0,5 MiB),
VirusTotal, `sha256sum -c SHA256SUMS.txt`, `gh attestation verify`, cài đè gói chính trên máy giữ dữ liệu, `cpu_rate`
bản release ở Đo mức.

### P4. Hàng đợi STATE (khi P1-P3 xong)

Dependabot nhóm npm mới (merge khi 0 check không đạt), V1 bước 3-4 (đo ba repo đóng gói), ADR-0006/tsusync (chờ 👤),
GP1, Play Billing, winget - như `logs/STATE.md`.

## 3. Công cụ đo đã có trong repo (đừng viết lại)

- **CPU theo tab**: `scripts/android/qa11-cpu.sh <nhãn> [số vòng]` - gói `.profile`, mở app, đo yên, bấm Bắt đầu đo, mỗi
  vòng qua Đo mức / Phân tích / Công cụ (Bộ chỉnh âm) / Cài đặt, `cpu_rate 20` mỗi tab, cuối cùng Tạm dừng. Toạ độ cho màn
  1080×2400. Kết quả TSV ở `$QA_DIR` (`logs/qa/<ngày>/`, bị `.gitignore` ⇒ chép số vào phiếu 06).
- **CPU theo luồng**: `scripts/android/thr.sh` - `adb push` lên `/data/local/tmp/`, chạy `sh /data/local/tmp/thr.sh <pid>`
  hai lần cách 20 s, `sort` rồi `join` theo tid (luồng sinh/mất giữa hai lần ⇒ `paste` lệch dòng, số vô nghĩa). Đẩy
  script thay vì lệnh lồng nháy: mksh của Android hiểu sai `(`/`)` trong `${s#*(}`.
- **DSP từng khâu (máy dev)**: `packages/dsp-dart/tool/bench.dart` (`dart compile exe`, chạy xen kẽ trước/sau + `taskset`).

## 4. Việc của chủ dự án (👤)

- Đồng ý gỡ worktree `~/projects/sound-db-qa11` (mục đầu phiếu).
- Giữ điện thoại cắm USB khi phiên sau làm P1/P3 (đừng đóng app Sound Db từ màn Gần đây khi đang đo).
- SEC2: đăng nhập/OTP trên Edge `tsudev-bp` nếu biểu mẫu đòi; bật Private vulnerability reporting nếu agent bị chặn.
- QR3 E2E, TalkBack nghe thật, DK2, Pro nghiệm thu, Required reviewers - như phiếu 07 mục 3.

## 5. Bẫy mới (bổ sung phiếu 07 mục 4 + 08 mục 4)

- **DSP nhanh trên x86 ≠ nhanh trên máy**: bench AOT chỉ đo DSP; trên máy thật chi phí lớn là dựng/vẽ widget. Luôn đo
  theo luồng trên máy trước khi chọn hướng.
- Mọi widget nghe `MeasurementController` (báo 20 lần/giây) PHẢI dùng `VisibleListenableBuilder` (`widgets/common.dart`),
  không dùng `ListenableBuilder` - nếu không trang ẩn lại dựng 20 lần/giây (test `hidden_pages_idle_test.dart` bắt).
- `git add logs/qa/...` bị `.gitignore` chặn - số đo phải chép vào phiếu.
- Đo `cpu_rate` ngay sau khi cài APK: app vừa cài chạy JIT/khởi tạo - chờ 5-6 s sau khi mở (script đã chờ).

## 6. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán NGUYÊN VĂN)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Trả lời tiếng Việt. Làm ĐÚNG THỨ TỰ dưới đây, không bỏ bước, không hỏi lại
điều đã có trong phiếu. Mục tiêu phiên: hoàn thành 100% phiếu logs/handover/20261125-09_ban-giao-sound-db.md mục 2
(P1 → P2 → P3 → P4), mỗi việc có bằng chứng.

0. ỦY QUYỀN SẴN: được tạo nhánh, commit, đẩy, mở PR, chờ CI và MERGE PR của chính phiên theo TÊN NHÁNH khi 0 check
   không đạt; được cài APK lên điện thoại đang cắm (adb.exe Windows); được deploy qua merge main. KHÔNG merge PR của
   Dependabot/người khác khi CI chưa xanh; KHÔNG chạy `adb usb`; KHÔNG sửa .standards/; KHÔNG tạo/đổi tên repo.

1. KHỞI ĐỘNG (đọc đúng phần cần, không đọc lại tệp vừa ghi):
   - CLAUDE.md, AGENTS.md (B.3, B.4, B.5), logs/STATE.md, logs/LOCKS.md.
   - Phiếu 09 TOÀN BỘ (việc chính); phiếu 07 mục 4 + phiếu 08 mục 4 (bẫy); phiếu 06 mục 6 dòng QA-11 (số đo).
   - Trước P2: phiếu logs/handover/20261125-SEC2_* + phiếu gốc ~/projects/logs/handover/20261125-SEC2_*-toan-he.md mục 0-2.
   - `akb start "sound-db: phiếu 09 - QA-11 bước 3, SEC2, phát hành"`; `akb search "QA-11"`, `akb search "IndexedStack"`,
     `akb search "SEC2"` TRƯỚC khi tự mò.
   - `git status`, `git log --oneline -5`, `gh pr list`, ListAgents (phiên khác có dùng điện thoại/Edge tsudev-bp không),
     `adb.exe devices -l` (trống ⇒ hỏi tôi cắm máy MỘT lần, trong lúc chờ làm P2).
2. GHI KHOÁ (logs/LOCKS.md) + dòng "Đang thực hiện" trong STATE trước khi sửa; nhả khoá NGAY khi xong từng vùng.
3. LÀM P1 (QA-11 bước 3): ĐO TRƯỚC (scripts/android/qa11-cpu.sh truoc 2 + thr.sh + DevTools CPU profiler bản profile ở
   tab Đo mức) ⇒ chọn khâu lớn nhất theo SỐ ĐO ⇒ test đỏ ⇒ sửa tận gốc ⇒ xanh ⇒ dựng profile (--build-number ≥ 26112502,
   không chạy lệnh flutter khác khi gradle đang dựng) ⇒ cài gói .profile ⇒ qa11-cpu.sh sau 2 ⇒ ghi bảng trước/sau vào
   phiếu 06 mục 6. Đổi thuật toán DSP ⇒ Rust + conformance/vectors.json + Dart CÙNG PR. Đạt < 30 jiffies/s ở Đo mức ⇒
   đóng QA-11; chưa đạt sau 2 vòng sửa ⇒ ghi số thật + hướng tiếp, KHÔNG nói "đạt".
4. LÀM P2 (SEC2) đúng mục 2.P2 phiếu 09: security.txt + test Expires, docs/security/trust.json, trang /security (vi + en),
   SSL Labs + Observatory đo thật (Edge hồ sơ tsudev-bp qua CDP, một phiên một lúc, đóng Edge khi xong), chỉ hiện mục có
   liên kết bên thứ ba + ngày đo, KHÔNG nhãn trang trí. Kiểm production bằng NỘI DUNG (`curl ... | grep "Báo lỗ hổng"`).
   Xong ⇒ ghi phiếu SEC2 + hàng sound-db ở bảng mục 3 phiếu gốc ⇒ SendMessage phiên tsudev điều phối.
5. LÀM P3 (phát hành) theo mục 2.P3 phiếu 09 (versionCode arm64 > 26114401; nghiệm thu SHA256 + attestation + cài đè
   giữ dữ liệu + cpu_rate bản release). Rồi P4 hàng đợi STATE.
6. NGUYÊN TẮC: mọi kết luận có số đo/log/ảnh; lỗi mới ⇒ QA-nn ở phiếu 06; widget nghe MeasurementController dùng
   VisibleListenableBuilder; chỉ `dart format -l 120` tệp mình sửa (hoặc không format); bí mật chỉ qua tsu-nhan-bi-mat;
   KHÔNG câu "do AI"/"Generated with"/Co-Authored-By trong commit, PR, tài liệu, ghi chú phát hành; lỗi > 10 phút ⇒
   `akb new issue`, mẹo ⇒ `akb new lesson`.
7. PR/CI: mỗi vùng một PR; chạy cổng tại máy phần bị sửa (flutter analyze --fatal-infos + flutter test; dart test DSP;
   npm test && npm run build cho web) trước khi đẩy; chờ CI bằng vòng `gh pr checks <nhánh>` chạy nền; job macOS bị huỷ
   không bước nào ⇒ `gh run rerun --failed`.
8. KẾT THÚC (kể cả khi sắp hết hạn mức - ưu tiên làm mục này trước khi cạn): phiếu 06 + STATE + phiếu bàn giao mới
   logs/handover/<YYYYMMDD>-NN_ban-giao-sound-db.md (khuôn như phiếu 09, có prompt cho phiên sau), PR + merge,
   `akb close <SES> "<tóm tắt>"` + `akb sync --project sound-db`, main sạch, LOCKS trống, dừng tiến trình nền của chính
   phiên. Báo cáo cuối: đã xong gì (kèm số đo), còn gì, việc 👤.
```
