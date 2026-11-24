# Nhật ký thay đổi

Theo `.standards/docs/VERSIONING.md` mục 3. Ngày dạng DD/MM/YYYY.

## [Chưa phát hành]

- iOS chờ tài khoản Apple Developer.

## 26.11.2501 - 25/11/2026

### Thay đổi
- Đo ở màn Đo mức tốn ít CPU và pin hơn khoảng một nửa (điện thoại thật: ~0,8 lõi ⇒ ~0,35 lõi): phổ tần số chỉ tính đủ
  nhịp khi trang Phân tích đang mở, màn Đo mức chỉ vẽ lại phần có số đổi, số đo cập nhật 10 lần/giây (QA-11).
- Website: trang Bảo mật và bằng chứng tin cậy `/security/` - báo lỗ hổng qua security@tsudev.com, kết quả SSL Labs,
  Mozilla Observatory, OpenSSF kèm liên kết kiểm chứng và ngày đo.

### Changed (en)
- Measuring on the Meter screen uses about half the CPU and battery (real phone: ~0.8 core ⇒ ~0.35 core): the frequency
  spectrum is computed at full rate only while Analysis is open, the Meter screen redraws only what changed, readings
  refresh 10 times per second (QA-11).
- Website: new Security and trust evidence page `/en/security/` - report vulnerabilities to security@tsudev.com, SSL Labs,
  Mozilla Observatory and OpenSSF results with verification links and dates.

## 26.11.2401 - 24/11/2026

### Mới
- Lịch sử (app + web): tìm theo nhãn/ghi chú không cần gõ dấu ("duong giai" khớp "đường giai") và lọc theo khoảng
  thời gian (7 ngày qua, 1 tháng qua, 1 năm qua, tuỳ chọn).
- Đăng nhập bằng mã QR: ở màn Đăng nhập chọn "Quét để đăng nhập", quét mã hiện ở tsudev.com trên máy tính đã đăng nhập
  (Android cần Google Play Services; luôn có nút đăng nhập thường). Màn đăng nhập thống nhất với hệ TsuDEV.

### Sửa
- Lịch sử tự cập nhật ngay sau khi lưu phiên đo, không cần bấm Tải lại (QA-07).
- Chữ cỡ lớn (200 %) + bàn phím mở: kết quả tìm Lịch sử vẫn hiện và cuộn được, chân bảng không tràn (QA-08).
- Máy phát tín hiệu dừng hẳn khi app ra nền (an toàn thính giác) và nút hiển thị đúng trạng thái khi quay lại (QA-09).
- Khi quyền micro bị từ chối vĩnh viễn, thông báo lỗi có nút "Mở cài đặt" tới trang quyền của app (Android) (QA-10).
- Biểu tượng thanh điều hướng đủ tương phản (4,45:1 giao diện Sáng, 6,21:1 Tối; trước đó ~1,2:1).

### Thay đổi
- Logo vector mới (xoá nền), biểu tượng app dựng lại từ vector - nét hơn ở mọi cỡ; dấu hiệu TsuDEV trước liên kết
  tsudev.com.

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
