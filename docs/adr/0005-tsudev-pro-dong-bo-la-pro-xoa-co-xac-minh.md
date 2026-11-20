# ADR-0005: Đồng bộ đám mây là TsuDEV Pro - máy chủ kiểm quyền qua kênh RP, xoá có xác minh

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 20/11/2026
- **Người quyết định**: agent-sound, theo quyết định chủ dự án 19-20/11/2026 (phiếu `20261119-PRO1`, `20261120-PRO2`)
- **Hợp đồng**: tsudev-standards v4.1.0 `docs/PRODUCT_POLICY.md` mục 3.3, 7.1-7.6, 8. Lệch ⇒ PRODUCT_POLICY thắng.

## 1. Bối cảnh

Trước PRO1, ai đăng nhập cũng đồng bộ miễn phí (ADR-0003, ADR-0004). Từ 19/11/2026: bản miễn phí lưu cục bộ, không
gửi dữ liệu người dùng lên mạng (N2); đồng bộ + sao lưu đám mây là **TsuDEV Pro** (N3) - gói chung 490.000 ₫ / 1 năm,
không tự gia hạn. Kiểm kê (PRO1 mục 2.1): dữ liệu rời thiết bị trước đây = bản ghi `session` (tóm tắt, chuỗi LAeq/giây,
phổ 1/3 octave) + `calibration`, tên/nền tảng thiết bị; không âm thanh, không vị trí. Chưa có người dùng thật ⇒ tắt
đồng bộ miễn phí thẳng, không ân hạn (PRO1 mục 5, Q2).

## 2. Quyết định

1. **Máy chủ Sound Db là RP** (ADR-0003 giữ nguyên): app không cầm token tsudev ⇒ máy chủ lấy quyền lợi thay app.
   - Kênh RP `GET https://tsudev.com/api/rp/entitlements/{sub}` (JWS `tsu-ent+jwt`, `aud` = `sounddb`), xác thực bằng
     client assertion `private_key_jwt` ES256 (`iss` = `sub` = `sounddb`, `aud` = đúng URL kênh, `exp` 120 giây, `jti`
     ngẫu nhiên). Máy chủ kiểm JWS bằng JWKS của tsudev (`iss`, `aud`, `typ`, `exp`, `exp` ≤ `iat` + 7 ngày, chỉ ES256).
   - Grant OIDC hết (kênh RP 404) ⇒ hỏi **kênh trạng thái** lấy `pro_until` (máy chủ vẫn kiểm được Pro; app không có JWS
     ⇒ hiện như miễn phí, cần đăng nhập lại để có huy hiệu/nhắc).
   - Đệm quyền lợi ≤ 24 giờ ở bảng `entitlements` (migration `0002`). tsudev.com lỗi: đệm còn hạn ⇒ dùng; hết ⇒ `503
     entitlements_unavailable` + `Retry-After` (KHÔNG coi là hết Pro). Chưa đặt khoá RP ⇒ không ai là Pro.
   - App gửi `X-Tsu-Installation` (mã cài đặt 128 bit của `tsudev_ui`) + `X-Tsu-Platform` khi gọi
     `GET /api/v1/me/entitlements`; máy chủ chuyển nguyên (đã kiểm khuôn) cho tsudev.com để đếm `devices_30d`.
2. **Gate ở máy chủ (N4)**: `POST /api/v1/sync/push` và sửa phiên đo từ web (`PATCH /api/v1/sessions/:id`) ⇒ không Pro
   còn hạn = `402 {"error":"pro_required"}`, kiểm TRƯỚC khi đọc thân yêu cầu. Kéo, xuất JSON, xoá vẫn mở (hết Pro vẫn
   kéo/xuất được 90 ngày - 7.2; xoá là quyền của người dùng).
3. **App (N2)**: chỉ đẩy khi JWS quyền lợi còn hạn nói Pro (`tsudev_ui` `EntitlementsRepository`, app tự kiểm chữ ký -
   không tin máy chủ Sound Db) ⇒ bản miễn phí gửi 0 byte dữ liệu đo. Gặp `402` ⇒ dừng đẩy, không thử lại tới khi quyền
   lợi đổi. Dữ liệu trên thiết bị không bao giờ bị xoá vì hết Pro.
4. **Màn Pro / Ủng hộ**: điều khoản 7.5 nguyên văn đứng trước nút mua (test so với `.standards` ở app + cổng
   `check-dist` ở web). Ngoài cửa hàng ⇒ `https://tsudev.com/pro?app=sounddb`, Ủng hộ ⇒ `/ung-ho?app=sounddb`. Bản Play
   (`--dart-define=SOUNDDB_STORE=play`) KHÔNG dẫn ra web; Play Billing (`tsudev_pro`/`nam`) nối khi tsudev xong B2.
5. **Nhắc** (7.3, 7.6): `ProNotice` + `ProRenewalNotice` của `tsudev_ui` v0.2.0 (6 + 5 test bắt buộc nằm ở gói dùng chung),
   hiện ở màn chính sau khi làm mới quyền lợi, mỗi lần tối đa một hộp thoại; "Sao lưu ra tệp (miễn phí)" ⇒ màn Lịch sử
   (xuất CSV/JSON).
6. **Xoá có xác minh** (7.4, PRO2 2.3): tài khoản còn bản ghi mà `pro_until` đệm + 90 ngày đã qua (kể cả chưa từng
   Pro - dữ liệu thử nghiệm trước PRO1) ⇒ NGAY TRƯỚC khi xoá hỏi kênh trạng thái: còn hạn + 90 ngày ⇒ cập nhật, GIỮ;
   `ok` quá 90 ngày / `deleted` ⇒ xoá (ghi `audit_log` `cloud_purged`); `unknown_subject` / lỗi ⇒ hoãn, không hỏi lại
   trong 24 giờ. Không có khoá RP ⇒ hoãn tất. Chạy kèm ~1% yêu cầu `/api/*` (hết Cron miễn phí), ≤ 20 tài khoản/lượt.
7. Máy chủ Sound Db **không** nhận JWS do app gửi lên làm thẻ ⇒ quy tắc `iat` ≤ 24 giờ (7.4) không áp dụng ở đây.

## 3. Lệch chuẩn đã biết (ghi ở AGENTS.md B.4)

- **N3 mã hoá đầu cuối**: bản ghi đồng bộ đang lưu dạng rõ trong D1 để bảng điều khiển web đọc được. Kế hoạch: chuyển
  sang TsuDEV Sync (`tsusync`, libsodium secretstream + Argon2id) khi thư viện Dart `tsusync` ổn định; web khi đó giải mã
  phía trình duyệt bằng mật khẩu đồng bộ. Đến lúc đó chỉ người dùng Pro có dữ liệu trên máy chủ.
- **i18n**: app/web hiện chỉ tiếng Việt; hộp thoại của `tsudev_ui` tự theo ngôn ngữ máy. Nợ chung với checklist mục 8.

## 4. Mối đe doạ (bổ sung `docs/THREAT_MODEL.md`)

| Đe doạ | Chặn |
| --- | --- |
| App sửa cờ Pro / giả JWS | Máy chủ tự hỏi tsudev.com; app chỉ ẩn/hiện. JWS sai chữ ký/`aud`/`typ`/hết hạn/`exp` quá 7 ngày bị từ chối (test) |
| Lộ khoá RP | Chỉ ở secret Worker `RP_PRIVATE_JWK` + `~/.config/tsudev/sounddb/` (600); assertion sống 120 giây, `jti` một lần ở tsudev; thay khoá = đăng ký JWK mới |
| Xoá nhầm người gia hạn trên web | Kênh trạng thái ngay trước khi xoá (test "gia hạn trên web mà không mở app ⇒ không xoá + cập nhật hạn") |
| tsudev.com sập ⇒ xoá/khoá nhầm | Lỗi ⇒ hoãn xoá; gate trả 503 (không 402) khi không có đệm |
| Liệt kê thiết bị qua `X-Tsu-Installation` | Chỉ chuyển giá trị đúng khuôn 22 ký tự base64url; không lưu ở máy chủ Sound Db |
| Dội tsudev.com | `/me/entitlements` 30 lượt/phút/tài khoản; đệm 24 giờ cho gate; kênh trạng thái ≤ 1 lần/24 giờ/tài khoản |
