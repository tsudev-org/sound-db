# PHIẾU BÀN GIAO - APK Android ký số, Deploy tự động, bản 26.11.1705 (agent-sound)

- **Mã phiếu**: 20261117-05
- **Từ**: agent-sound - **Đến**: phiên kế tiếp của repo `sound-db` / chủ dự án (mục 3)
- **Thời điểm**: 21:30 17/11/2026
- **Trạng thái**: MỞ (còn việc 👤)
- **Nhánh git**: `main` sạch sau PR phiếu này. `logs/LOCKS.md` trống, không tiến trình nền.

## 1. Việc đã làm xong

- Secret `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` ở Environment `production` (lấy từ
  `~/.config/tsudev/cloudflare.env`, đã `chmod 600`; token `verify` = active, đọc được Workers + D1). Deploy chạy tay
  44090540556 đạt ⇒ PR #7 bật trigger `push`; lần tự động đầu tiên 44097415902 đạt nghiệm thu.
- Khóa ký Android: `~/.config/tsudev/android/upload.jks` (PKCS12, RSA 4096, alias `upload`, 10000 ngày) + mật khẩu
  trong `sound-db-upload.env` cùng thư mục (700/600). Chứng chỉ SHA-256
  `FE:18:37:83:E4:23:0B:E5:EC:68:A6:BA:63:51:96:CE:D0:36:EE:6B:37:91:75:14:5A:8A:16:4F:F0:E4:62:CE`.
  4 secret ở Environment `release`.
- Lỗi đã sửa (PR #7): `apps/app/android/app/build.gradle.kts` gọi `java.util.Properties` trong khối `android {}`,
  ở đó `java` là extension JavaPluginExtension ⇒ "Unresolved reference 'util'". Chỉ lộ khi có `key.properties`, nên
  CI (không có khóa) chưa bao giờ bắt được. Phát hiện bằng cách dựng thử APK ký số ở máy TRƯỚC khi tag.
- **v26.11.1705** phát hành 7/7 job: 2 APK + Windows + macOS + Linux, SHA256SUMS khớp, `apksigner` đúng khóa,
  `gh attestation verify` đạt. `/tai-ve/` hiện 26.11.1705 + dòng Android trỏ tới APK.
- Homebrew `cap-nhat` chạy tay ⇒ cask 26.11.1705.
- Phiếu đề xuất logo `20261117-04` (3 SVG trong `logs/handover/20261117-04_logo/`).
- Nhắn phiên `tsudev-e1` về client OIDC: trả lời là máy không có `~/.config/tsudev/neon.env` ⇒ chỉ chủ dự án chèn
  được; phiên tsudev sẽ nhắn lại `sound-db-ca` khi xong.

## 2. Việc dang dở + bước tiếp theo CỤ THỂ

- [ ] Scoop vẫn 26.11.1704: excavator (run 44099336322, 2 lần) dừng vì GitHub API 403 rate limit trên runner Windows,
  dù workflow đặt `SCOOP_GH_TOKEN`. Lịch `17 */6 * * *` UTC sẽ thử lại. Vẫn hỏng ⇒ phiếu cho phiên repo
  `scoop-bucket` (nghi checkver của Scoop không đọc biến `SCOOP_GH_TOKEN` mà đọc `scoop config gh_token`).
  Kiểm: `gh api repos/tsudev-org/scoop-bucket/contents/bucket/tsudev-sound-db.json -q .content | base64 -d | grep version`.
- [ ] Kho apt/rpm: lịch `xuat-ban` của linux-packages sẽ nhận 26.11.1705 và chờ chủ dự án duyệt.
- [ ] Cài thử APK trên thiết bị/emulator thật (máy dev không có emulator; `/dev/kvm` có sẵn nếu muốn cài
  `system-images;android-36;google_apis;x86_64`).
- [ ] Sau khi có client OIDC: đăng nhập thử web + app, nghiệm thu đồng bộ hai thiết bị.

## 3. Việc của chủ dự án (👤) - lệnh soạn sẵn

1. 👤 Client OIDC `sounddb`: SQL trong phiếu tsudev `20261117-SD1` mục 2 (hoặc đặt `~/.config/tsudev/neon.env` để phiên
   tsudev tự chèn).
2. 👤 Required reviewers (cần tài khoản admin repo; `tsudev-tsudev` bị 403):
   ```bash
   for e in release production; do
     echo '{"reviewers":[{"type":"User","id":291851597}]}' | gh api -X PUT repos/tsudev-org/sound-db/environments/$e --input -
   done
   ```
   Sau đó MỖI lần đẩy main sửa web/máy chủ sẽ chờ duyệt Deploy (agent không tự duyệt được).
3. 👤 Sao lưu `~/.config/tsudev/android/` (khóa + mật khẩu) ra ngoài máy. Mất khóa = không cập nhật được app.
4. 👤 Thu hồi token Cloudflare trong `cloudflare.env` khi không cần nữa - LƯU Ý: secret `production` dùng CHÍNH token
   đó; thu hồi ⇒ Deploy tự động hỏng. Nên tạo token riêng cho CI (quyền Workers Scripts + D1 Edit) và đặt lại secret.
5. 👤 Chọn logo (phiếu `20261117-04`).

## 4. Cảnh báo

- Tag `v26.11.1703` không có Release - đừng dùng lại số này.
- Đổi gì trong cấu hình ký Android ⇒ dựng thử `flutter build apk --release` VỚI `key.properties` ở máy; CI PR không có
  khóa nên không bắt được lỗi nhánh có khóa.
- versionCode APK tách ABI = `1000 × ABI + build`: arm64 26113705, x86_64 26115705.

## 4b. Cập nhật 22:00 17/11/2026 - OIDC

- Phiên tsudev đã chèn client `sounddb` (mục 3.1 XONG). `/auth/web/start` → `/oidc/auth` 303 → `/oidc/interaction/<uid>`
  nhưng trang đó trả 404 text/plain trên production (kể cả uid bịa; trang Next `[uid].tsx` lẽ ra chuyển sang
  `/login`). Lỗi phía tsudev, ảnh hưởng mọi client OIDC - đã báo phiên `tsudev-e1` kèm repro.

## 5. Trạng thái cổng kiểm

PR #7: 10/10 check xanh. Release 26.11.1705 7/7 job đạt. Deploy tự động đạt nghiệm thu production.
