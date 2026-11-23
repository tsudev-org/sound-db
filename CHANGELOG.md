# Nhật ký thay đổi

Theo `.standards/docs/VERSIONING.md` mục 3. Ngày dạng DD/MM/YYYY.

## [Chưa phát hành]

- iOS chờ tài khoản Apple Developer.

## 26.11.2302 - 23/11/2026

### Sửa
- Bấm "Tiếp tục" sau "Tạm dừng" không còn xoá phiên đang đo (đồ thị 2 phút, LAeq, Max/Min, giờ bắt đầu) (QA-03).
- Màn Đo mức và Phân tích chỉ vẽ lại khi có số liệu mới (20 lần/giây thay vì ~80): mượt hơn, đỡ tốn pin; phân tích
  phổ không còn chạy chen trong lúc vẽ khung hình (QA-04).
- Trình đọc màn hình (TalkBack/VoiceOver) không còn đọc dồn từng con số khi đang đo; chỉ thông báo khi mức âm chuyển
  vùng an toàn / cần lưu ý / nguy hại, chạm mặt đồng hồ để nghe số hiện tại (QA-05).

## 26.11.2301 - 23/11/2026

### Sửa
- Lịch sử trống trên một số điện thoại Android (SQLite của máy không có JSON1) dù đã báo "Đã lưu"; nay xếp theo cột
  thời gian riêng, nâng cấp dữ liệu cũ tự động, và báo lỗi rõ ràng thay vì màn trống (QA-01).
- Dải 1/3 octave bắt đầu đúng ở 10 Hz: hết nhãn trục "10 10 10 10" và cảnh báo "phủ 0,0 bin FFT" (QA-02).

### Thay đổi
- Bản sắc riêng của Sound Db (tsudev-standards v5.0.0): màu nhấn xanh vàng chanh, font tiêu đề Space Grotesk trên
  web, mặt đồng hồ mức âm ở màn Đo mức và trang chủ, hoạ tiết sóng âm.
- Tệp phát hành có thêm tên chuẩn `{os}-{arch}` (`sound-db_26.11.2301_windows-x64.zip`, `_android-arm64.apk`...) và
  `SHA256SUMS.txt`; tên cũ vẫn phát hành song song trong giai đoạn chuyển tiếp.

### Thêm
- `CONTRIBUTING.md` (tiếng Anh), tóm tắt tiếng Anh ở README/SECURITY, hồ sơ OpenSSF Best Practices
  (`docs/best-practices.*`) và fuzz test cho lõi DSP (`packages/dsp-core/tests/fuzz.rs`).

## 26.11.1705 - 17/11/2026

### Thêm
- Android: APK ký số cho arm64 và x86_64 (Android 7.0 trở lên), kèm SHA-256 và chứng thực nguồn gốc.

## 26.11.1704 - 17/11/2026

(26.11.1703 không phát hành: bản dựng Linux hỏng ở bước cài công cụ.)

### Sửa
- Bản Linux chạy được trên Debian 12 và Ubuntu 22.04 (trước đây báo thiếu `GLIBC_2.38` vì dựng trên Ubuntu 24.04).

## 26.11.1702 - 17/11/2026

### Sửa
- Trang Lịch sử không hiện phiên đo nào trên máy dùng SQLite mới (truy vấn sắp xếp sai cú pháp).
- Nhãn tần số dưới phổ đồ và chân bảng phân trang bị tràn trên màn hình điện thoại.
- Đăng nhập không còn dùng khung web nhúng: điện thoại mở trình duyệt hệ thống, máy tính dùng vòng lặp 127.0.0.1.

### Thêm
- iOS: phiên âm thanh chế độ đo lường (tắt tự động tăng âm, khử ồn của hệ thống).
- Biểu tượng ứng dụng trong gói Linux; cài bằng lệnh qua Scoop (`scoop install tsudev/tsudev-sound-db`) và
  Homebrew (`brew install tsudev-org/tap/tsudev-sound-db`).

## 26.11.1701 - 17/11/2026

Bản phát hành đầu: Windows, macOS, Linux trên GitHub Releases; website và máy đo trên trình duyệt tại
sounddb.tsudev.com.

### Thêm
- Lõi DSP Rust `sounddb-dsp`: trọng số A/C/Z (IEC 61672-1, lệch < 0,05 dB tới 12,5 kHz), F/S/I, Leq, Lmax/Lmin,
  Lpeak, LAFn, SEL, liều NIOSH/OSHA, FFT 5 cửa sổ, tần số trội trọng tâm công suất, dải 1/1 và 1/3 octave
  (IEC 61260-1), cao độ McLeod, bộ phát tín hiệu, lớp vỏ WebAssembly.
- Bản Dart của lõi DSP, khớp vector đối chiếu do bản Rust sinh ra.
- App Flutter (Android, iOS, Windows, macOS, Linux): đo mức, phổ, phổ đồ, octave, cao độ, phát tín hiệu,
  hiệu chuẩn, lịch sử phân trang, xuất CSV/JSON, đăng nhập tsudev, đồng bộ, chế độ ngoại tuyến hoàn toàn.
- Máy chủ Cloudflare Workers + D1: đăng nhập qua tsudev.com, token app xoay vòng, đồng bộ, xuất/xóa dữ liệu.
- Website sounddb.tsudev.com: giới thiệu, máy đo trên trình duyệt, bảng điều khiển tài khoản.
