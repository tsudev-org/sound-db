# 20261120-GP1 - sound-db: đưa Sound Db lên Google Play Console (phần B của phiếu toàn hệ)

- **Người lập**: phiên điều phối `tsudev-62`, 20/11/2026.
- **Người làm**: phiên sound-db. **Trạng thái**: MỞ.
- **Phiếu mẹ**: `~/projects/logs/handover/20261120-GP1_google-play-console-toan-he.md` - làm theo **mục 4 (checklist
  mỗi app)**; mục 2 (phần A dùng chung) ĐÃ XONG ở phiên tsudev, đừng làm lại.
- **Công cụ trình duyệt**: `~/projects/logs/tools/browser/README.md` (`tsb`, hồ sơ `play` = Edge `tsudev-play`, đã đăng
  nhập Play Console). Dùng tsb, KHÔNG viết script Playwright thô không rào chắn.

## 1. Hiện trạng (đo 20/11/2026)

| Package | Trên Play Console | Pro/ủng hộ qua Play |
|---|---|---|
| `com.tsudev.sounddb` | ❌ chưa tạo | chưa bán qua Play (RP key đã có - phiếu SDB1); đã có sẵn trong `PLAY_PACKAGES` (`sounddb=com.tsudev.sounddb`) |

## 2. Việc riêng của repo này

1. Quyền **micro**: khai lý do ở Quyền truy cập + An toàn dữ liệu. KIỂM MÃ trước khi khai rằng âm thanh chỉ xử lý trên máy, không ghi/gửi đi (đo bằng grep mạng + quyền trong manifest, ghi bằng chứng vào phiếu).
2. Tạo app mới (GP1 mục 4 bước 1) rồi đủ "Thiết lập ứng dụng".
3. Nếu bán Pro/ủng hộ qua Play: tạo `tsudev_pro` (một gói `nam` P1Y trả trước) + 4 sản phẩm `ung_ho_*` (bước 4).

## 3. Ranh giới

- Nút gửi duyệt / xuất bản / thanh toán / xoá app: **👤 bấm** (tsb chặn sẵn) - agent điền rồi dừng, chụp màn hình.
- Danh sách ≥ 12 người thử kín, hồ sơ thanh toán, mật khẩu tài khoản thử cho người duyệt: 👤.
- Không tạo khoá tài khoản dịch vụ mới; `tsudev-play-verify` đã có quyền mức tài khoản (phủ app mới).
- Bằng chứng: ảnh "Tổng quan về việc xuất bản" vào `logs/trust/`, ghi `logs/trust/TRUST.md`.

## 4. Xong khi

GP1 mục 4 bước 1-7 đạt cho app này; ghi một dòng vào mục 5 phiếu này VÀ mục 6 phiếu mẹ.

## 5. Kết quả xử lý (mỗi phiên ghi một dòng)


- 20/11/2026 - `sound-db-32`: **2.1 kiểm mã quyền micro - ĐẠT, khai được "âm thanh chỉ xử lý trên máy"**. Bằng chứng (commit
  `a7ae352`+): manifest chỉ có `RECORD_AUDIO`, `INTERNET`, `WAKE_LOCK`; `lib/services/audio_input.dart:69`
  `startStream` PCM16 (luồng trong bộ nhớ, không `RecordConfig` ra tệp, không `writeAsBytes`/`.wav` trong `lib/`);
  luồng mẫu `samples` chỉ có MỘT nơi nghe: `lib/services/measurement.dart:86` (DSP). Gọi mạng chỉ ở
  `lib/sync/auth_service.dart` (đăng nhập + API đồng bộ: gửi bản ghi phiên = số liệu tóm tắt/LAeq theo giây, KHÔNG mẫu
  âm) và `lib/pro/pro_service.dart` (mở trang ủng hộ). An toàn dữ liệu: "Âm thanh" = KHÔNG thu thập; dữ liệu đo + tài
  khoản = có (chỉ người dùng Pro đồng bộ). Bước 1-7 trên Play Console: CHƯA làm (sound-db xếp thứ 4, phiếu mẹ mục 5);
  nên làm SAU bước B đổi tên miền (ADR-0007) để URL chính sách/website khai bằng `sound.tsudev.com`.

## Bổ sung 20/11/2026 (tsudev điều phối) - điền biểu mẫu đứng tên chủ dự án

Theo tsudev-standards v4.2.0 `STORE_SUBMISSION.md` mục 0.1 (PR tsudev-standards #65): mọi trường Play Console điền như
chủ dự án tự điền, KHÔNG chọn/ghi "do AI thực hiện". Câu hỏi về tính năng thật của app (có tính năng AI tạo sinh
không...) trả lời đúng mã, ghi tệp mã làm nguồn trong `docs/store/google-play.md`.
