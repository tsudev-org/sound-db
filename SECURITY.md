# Chính sách bảo mật - Sound Db

## Báo lỗ hổng

**KHÔNG mở issue công khai.** Dùng [Báo cáo lỗ hổng riêng tư của GitHub](https://github.com/tsudev-org/sound-db/security/advisories/new).
Gửi kèm: thành phần (app/web/máy chủ), phiên bản, cách tái hiện, tác động. Cam kết phản hồi trong 7 ngày, bản sửa
cho lỗi nghiêm trọng trong 30 ngày. Quy trình chung: [`.standards/SECURITY.md`](.standards/SECURITY.md).

## Phạm vi và biện pháp chính

- **Âm thanh không rời thiết bị**: chỉ xử lý trong bộ nhớ, không ghi âm; đồng bộ chỉ chở con số đo.
- **Không gọi mạng khi chưa đăng nhập**; công tắc *Chế độ ngoại tuyến hoàn toàn* chặn mọi kết nối.
- **Đăng nhập**: OIDC Authorization Code + PKCE S256 tới tsudev.com qua trình duyệt hệ thống (không WebView);
  `state` gắn với trình duyệt bằng cookie `__Host-`, `nonce` kiểm trong `id_token` (ES256, JWKS theo `kid`).
- **Token app**: access JWT 15 phút; refresh token mờ, chỉ lưu SHA-256, xoay vòng mỗi lần dùng, dùng lại token đã
  xoay ⇒ thu hồi cả thiết bị. Refresh token trên máy nằm trong kho bí mật của hệ điều hành.
- **Web**: cookie phiên `__Host-` HttpOnly Secure SameSite=Lax; mọi lệnh ghi đòi `Origin` đúng + header chống CSRF;
  CSP không `unsafe-inline`/`unsafe-eval`, WebAssembly và micro chỉ mở ở trang `/do/`.
- **Máy chủ**: kiểm lược đồ chặt (zod, có trần kích thước), cô lập dữ liệu theo người dùng ở mọi truy vấn, giới hạn
  tần suất, nhật ký bảo mật lưu IP dạng băm có muối.

Mô hình mối đe dọa chi tiết: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) mục 6.

## Kiểm chứng bản tải về

Mỗi bản phát hành kèm `SHA256SUMS` và chứng thực nguồn gốc bản build (GitHub Artifact Attestations):

```bash
gh attestation verify <tệp> --repo tsudev-org/sound-db
```
