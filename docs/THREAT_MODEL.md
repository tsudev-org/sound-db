# THREAT_MODEL - Sound Db

Mô hình mối đe doạ rút gọn (SECURITY_BASELINE). Dữ liệu cao nhất D2: tài khoản + số đo cá nhân; không âm thanh, không
vị trí. Chi tiết từng quyết định ở `docs/adr/`.

| Tài sản / luồng | Đe doạ | Chặn | Nơi |
| --- | --- | --- | --- |
| Đăng nhập OIDC qua máy chủ (RP) | Đánh cắp mã/token, CSRF đăng nhập | PKCE S256 hai chặng, state + binder cookie, redirect cố định, refresh token xoay vòng + phát hiện dùng lại | ADR-0003 |
| API ghi bằng cookie (web) | CSRF | `Origin` đúng gốc + header `X-Sdb-Csrf` | `auth/middleware.ts` |
| Bản ghi đồng bộ | Ghi đè/đồng hồ lệch | Ghi sau thắng, chặn `updated_at` > 1 ngày tương lai, giới hạn kích thước | ADR-0004 |
| Quyền lợi TsuDEV Pro | Giả Pro, lộ khoá RP, xoá nhầm, dội tsudev.com | Gate 402 ở máy chủ, JWS kiểm đủ, xoá có xác minh | ADR-0005 mục 4 |
| Bản miễn phí | Rò dữ liệu đo lên mạng | App không đẩy khi không có JWS Pro còn hạn (test `pro_test.dart`); chế độ ngoại tuyến chặn mọi kết nối | ADR-0005 |
| Trang máy đo `/do/` | XSS, WASM bị chặn | CSP riêng do Worker đặt, không script nội tuyến | AGENTS.md B.5 |
