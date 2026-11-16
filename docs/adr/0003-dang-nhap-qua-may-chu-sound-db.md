# ADR-0003: Đăng nhập tsudev đi qua máy chủ Sound Db, máy chủ cấp mã một lần + PKCE cho app

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-sound
- **Liên quan**: `services/sync-api/src/auth/*`, `apps/app/lib/sync/auth_service.dart`, tsudev `docs/auth.md` mục 8

## 1. Bối cảnh

IdP tsudev.com (`oidc-provider`) có ràng buộc đo được ngày 17/11/2026 (`src/oidc.ts`):

- Access token là token MỜ, `introspection` TẮT ⇒ API của Sound Db không tự kiểm được access token của tsudev.
- `clientBasedCORS: () => false` ⇒ trình duyệt không gọi được endpoint token ⇒ web không thể là client công khai.
- Client đọc từ bảng `OAuthClient` không có `application_type: native` ⇒ redirect scheme riêng và vòng lặp
  `http://127.0.0.1` của app gốc không đăng ký được.

## 2. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. App và web làm client OIDC trực tiếp | đúng sách | không chạy được với 3 ràng buộc trên; phải sửa tsudev |
| B. Dùng id_token của tsudev làm bearer cho API | đơn giản | sai mục đích id_token, hết hạn 15 phút, không thu hồi được |
| C. Máy chủ Sound Db là RP duy nhất (một redirect HTTPS), tự cấp phiên web và mã một lần + PKCE cho app | chạy ngay, chỉ cần đăng ký MỘT client; Sound Db tự kiểm soát thu hồi thiết bị | thêm một lớp máy chủ cấp phép |

## 3. Quyết định

Chọn **C** (mẫu "máy chủ liên kết danh tính", như các nền tảng xác thực phổ biến làm với Google/GitHub):

1. App mở trình duyệt hệ thống tới `/auth/app/start` kèm `redirect_uri` (khớp tuyệt đối danh sách:
   `com.tsudev.sounddb:/auth/callback` hoặc `http://127.0.0.1:<cổng>/callback`), `state`, `code_challenge` S256.
2. Máy chủ lưu yêu cầu (băm `state`, gắn cookie `__Host-sdb_login`), chuyển tới tsudev.com với PKCE + `nonce` riêng.
3. `/auth/callback`: kiểm cookie gắn trình duyệt, đổi mã ở endpoint token (máy chủ - máy chủ), kiểm `id_token`
   (ES256, `iss`, `aud`, `exp`, `nonce`, JWKS theo `kid`), đọc userinfo (cùng `sub`).
4. Cấp mã một lần 60 giây ràng buộc `redirect_uri` + `code_challenge` của app; app đổi bằng `code_verifier`.
5. Token app: access JWT HS256 15 phút + refresh mờ xoay vòng 30 ngày, phát hiện dùng lại.

## 4. Hệ quả

- Việc của chủ dự án: đăng ký client `sounddb` với redirect `https://sounddb.tsudev.com/auth/callback`
  (phiếu `logs/handover/20261117-01_*`).
- Không giữ token của tsudev.com: chỉ dùng một lần lúc đăng nhập.

## 5. Đường lùi

Khi tsudev bật JWT access token có `aud` cho tài nguyên Sound Db + client native, app có thể nói chuyện thẳng với
IdP; máy chủ chỉ còn kiểm JWT. Bảng `users.oidc_sub` giữ nguyên nên không mất dữ liệu.
