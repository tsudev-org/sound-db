# PHIẾU BÀN GIAO 20261124-08 - sound-db, cuối phiên `sound-db-56` (24/11/2026)

- **Từ**: agent-sound phiên `sound-db-56` (tiếp `sound-db-f9` + `sound-db-10`, hai phiên bị tắt đột ngột) - **Đến**: phiên
  agent-sound kế tiếp (+ 👤 chủ dự án ở mục 3)
- **Thời điểm**: tối 24/11/2026 - **Trạng thái**: MỞ
- **Git**: `main` sạch sau PR #54-#56; `logs/LOCKS.md` trống; không tiến trình nền của phiên. `apps/app/android/.kotlin/`
  (thư mục phiên Kotlin của gradle, không phải của phiên này) để nguyên, chưa commit.
- **Phiếu thay thế**: `20261124-07` (mục 2 bước 1-3 đã xử lý xong ở đây; mục 3-5 vẫn giữ nguyên giá trị).
- **AKB**: `SES-20261124-2245-4100`, `LES-20261124-2302-4693`. Hai SES rỗng của phiên bị tắt: `SES-20261124-2015-9e9a`,
  `SES-20261124-2230-9daa` (interrupted, không có ghi chép - mọi thứ chúng làm đều đã ở git).

## 1. Đã xong

| Việc | PR | Bằng chứng |
| --- | --- | --- |
| Bản **26.11.2401** (phiên `sound-db-f9`) | #53 | Release Latest, run 45409204596 đạt; CI/Deploy/CodeQL xanh |
| **QA-11** CPU khi đo - sửa phần lớn | #54 | `tool/bench.dart`; 126 762 giá trị trùng bit; x86 105-129k ⇒ 22-35k µs CPU/giây âm (~-75 %) |
| Dependabot npm bỏ qua TypeScript ≥ 7, vitest/@vitest ≥ 5 | #55 | `.github/dependabot.yml`, lý do + điều kiện bỏ chặn ghi trong tệp |

Chi tiết QA-11: phiếu 06 mục 6. Hai thay đổi: (1) `SpectrumAnalyzer` lập sẵn bảng dải octave + hệ số trọng số (không đổi
thuật toán, Rust + `vectors.json` không đổi); (2) chỉ dò cao độ khi tab Bộ chỉnh âm hiển thị - vỏ app bọc
`TickerMode(enabled: i == _index)` cho trang ẩn của `IndexedStack` (Flutter 3.47 KHÔNG tự tắt). App 73 test.

## 2. Việc còn lại - làm theo thứ tự

1. **QA-11 đo máy thật** (cần 👤 cắm SM-M325FV): dựng bản profile, `scripts/android/ui.sh` `cpu_rate` 20 s ở Đo mức /
   Phân tích / Bộ chỉnh âm / Cài đặt; so với 24/11 (84-93 jiffies/s). Mục tiêu < 30 ở Đo mức. Chưa đạt ⇒ khâu lớn nhất
   còn lại là FFT (phổ 8192 + NSDF 8192 thuận/ngược): FFT thực đóng gói N/2 phức - đổi số học ⇒ Rust tham chiếu +
   `vectors.json` + Dart CÙNG PR; hoặc NSDF chỉ 10 lần/giây ở Bộ chỉnh âm. Đạt ⇒ đóng QA-11, đưa vào bản phát hành kế.
2. **Phát hành bản sửa kế tiếp** khi QA-11 đo xong (versionCode arm64 = số dựng + 2000, > bản đang cài).
3. Dependabot: PR nhóm npm mới (sau #55) nhận được nếu CI xanh - merge theo TÊN NHÁNH, chỉ khi 0 check không đạt.
4. Hàng đợi trong `logs/STATE.md` (ADR-0006/tsusync, GP1, V1 bước 3-4, Play Billing, winget...).

## 3. Việc của chủ dự án (👤)

- **Cắm điện thoại** (USB, adb.exe Windows) để đo QA-11; "unauthorized" ⇒ thu hồi uỷ quyền gỡ lỗi USB, cắm lại, tích
  "Luôn cho phép". ĐỪNG để agent chạy `adb usb`.
- QR3 E2E, TalkBack nghe thật, DK2, Pro nghiệm thu, Required reviewers - như phiếu 07 mục 3.

## 4. Bẫy mới

- `IndexedStack` (Flutter 3.47) giữ `TickerMode` BẬT cho trang ẩn - đừng dùng nó làm tín hiệu "đang hiển thị" nếu chưa
  có lớp bọc ở `app.dart`.
- So hiệu năng trên máy dev đông phiên: chạy xen kẽ trước/sau nhiều lượt, `taskset -c N`.
- `dart format` mặc định 80 cột định dạng lại cả tệp (repo viết 120, CI không kiểm) ⇒ không format cả tệp đang sửa.

## 5. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán nguyên văn)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Làm đúng thứ tự, trả lời tiếng Việt.

1. KHỞI ĐỘNG: CLAUDE.md, AGENTS.md (B.4, B.5), logs/STATE.md, logs/LOCKS.md, phiếu
   logs/handover/20261124-08_ban-giao-sound-db.md (VIỆC CHÍNH mục 2, bẫy mục 4; phiếu 07 mục 4 vẫn áp dụng), phiếu
   20261117-06 mục 6 (QA-11). `akb start`, `akb search` trước khi tự mò. `git status`, `gh pr list` (Dependabot: đọc,
   merge theo tên nhánh khi 0 check không đạt). ListAgents.
2. GHI KHOÁ + "Đang thực hiện" trong STATE trước khi sửa; nhả khoá ngay khi xong.
3. LÀM phiếu 08 mục 2: (1) QA-11 đo máy thật (adb.exe devices trống ⇒ hỏi tôi cắm máy một lần, làm việc khác trong
   lúc chờ), (2) phát hành bản sửa, (3) Dependabot, rồi hàng đợi STATE.
4. NGUYÊN TẮC: kết luận có số đo; Rust là tham chiếu DSP; không sửa .standards/; bí mật chỉ qua tsu-nhan-bi-mat; không
   câu "do AI"/Co-Authored-By trong commit, PR, tài liệu.
5. KẾT THÚC: phiếu 06 + STATE + phiếu bàn giao mới, PR + merge, `akb close` + `akb sync --project sound-db`, main sạch,
   LOCKS trống.
```
