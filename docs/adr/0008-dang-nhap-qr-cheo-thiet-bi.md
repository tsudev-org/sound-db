# ADR-0008: Đăng nhập bằng mã QR (chéo thiết bị) - app chỉ làm vai "thiết bị mới", giữ nguyên ADR-0003

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 24/11/2026
- **Người quyết định**: agent-sound theo phiếu điều phối `20261124-QR1` (QR3), chủ dự án uỷ quyền chọn phương án
  24/11/2026; hướng giao thức chốt cùng phiên tsudev (tsudev-standards `CROSS_DEVICE_LOGIN.md` v1.1.0, PR #76).

## 1. Bối cảnh

Chuẩn `CROSS_DEVICE_LOGIN` v1.0.0 gắn mã uỷ quyền QR với khoá DPoP tạm của thiết bị mới. Sound Db là RP **qua máy chủ**
(ADR-0003): máy chủ giữ PKCE verifier, đổi mã ở token endpoint, app không cầm token tsudev ⇒ máy chủ không có khoá DPoP
của app nên không đổi được mã. Agent nêu xung đột này cho IdP (phiếu QR1, 24/11); bản v1.1.0 đổi giao thức: kết quả QR
là **vé một lần đổi thành phiên tsudev.com trong trình duyệt**, sau đó RP đi luồng OIDC + PKCE như cũ.

## 2. Quyết định

1. **Vai thiết bị mới (Đ1) - có**: màn đăng nhập thống nhất `TsuSignInScreen` (tsudev_ui v0.4.0, AUTH 13.2/13.4) có
   "Quét để đăng nhập" trên Android/iOS. Bộ quét (`mobile_scanner`, quyền camera xin lúc bấm) chỉ nhận mã qua
   `TsuXdLink.parse` (T9); mã hợp lệ ⇒ mở chính `https://tsudev.com/x/<id>?f=d#<bí mật>` trong **trình duyệt hệ thống**
   (trang đó lo Cho phép, email che, mã khớp) ⇒ người dùng bấm "Tiếp tục đăng nhập" ⇒ luồng ADR-0003 không đổi, phiên
   tsudev vừa tạo trong cùng trình duyệt nên `/authorize` trả mã ngay. Máy chủ Sound Db KHÔNG có mã/bảng QR nào.
2. **Vai xác nhận (Đ2) - không làm ở app này**: cần access token tsudev + DPoP, app không giữ (ADR-0003). Mã `f=k` ⇒
   thông báo "quét bằng app tsudev đã đăng nhập". Máy tính dùng Đ2 sẵn có ở trang đăng nhập của tsudev.com.
3. **Máy tính (Windows/macOS/Linux)**: không có lối quét (không giả định camera sau); đăng nhập mở trình duyệt hệ thống
   như cũ, QR Đ2 nằm ở trang tsudev.com.
4. **Kích thước**: Android dùng ML Kit **unbundled** (`android/gradle.properties`) - bản nhúng thêm 3-10 MB/ABI, vượt
   ngân sách APK 25 MB (LANGUAGE_SELECTION 5.1); đổi lại máy không có Google Play Services không quét được (vẫn đăng
   nhập bằng nút thường).

## 3. Hệ quả

- Thêm quyền `CAMERA` (plugin khai, `uses-feature camera required=false`) + `NSCameraUsageDescription` (vi; bản en cùng
  đợt `InfoPlist.strings` của micro - AGENTS B.4). Hồ sơ cửa hàng (Play Data safety, App Privacy): camera chỉ để quét
  mã, không thu/lưu ảnh.
- Không thêm API máy chủ, không đổi client OIDC `sounddb`, không đổi ADR-0003/0005/0007.
- Kiểm thử: `test/qr_sign_in_test.dart` (T9: tên miền giả, http, cổng, userinfo, tham số thừa, đường dẫn lạ, thiếu bí
  mật, mã Wi-Fi; Đ2 không mở; lối quét chỉ trên điện thoại). E2E Đ1 trên máy thật cần một máy tính đã đăng nhập tài
  khoản tsudev thật (👤).

## 4. Phương án đã loại

- App tự gọi `/api/xd` + giữ phiên QR: trái `CROSS_DEVICE_LOGIN` mục 2 (chỉ IdP làm).
- Máy chủ Sound Db nhận mã uỷ quyền gắn DPoP của app: không đổi được mã (không có khoá) - lý do v1.1.0 đổi giao thức.
- ML Kit nhúng: vượt ngân sách APK.
