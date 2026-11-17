# Nhật ký thay đổi

Theo `.standards/docs/VERSIONING.md` mục 3. Ngày dạng DD/MM/YYYY.

## [Chưa phát hành]

- Android (APK ký số) chờ khóa ký; iOS chờ tài khoản Apple Developer.

## 26.11.1703 - 17/11/2026

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
