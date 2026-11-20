# Kiến trúc - Sound Db

Cập nhật: 17/11/2026.

## 1. Tổng quan

```
             +-------------------- tsudev.com (IdP OIDC) --------------------+
             |  Google / GitHub / tài khoản TsuDEV   ·  ES256, PKCE bắt buộc  |
             +-------------------------------+-------------------------------+
                                             | Authorization Code + PKCE (máy chủ - máy chủ)
                                             v
  +-----------------------------------------------------------------------------------+
  | sound.tsudev.com (+ tên cũ sounddb.tsudev.com) - MỘT Cloudflare Worker             |
  |   tệp tĩnh (Astro): trang giới thiệu, /do/ máy đo WASM, /bang-dieu-khien/           |
  |   /auth/*   : RP OIDC, cấp mã một lần cho app, cookie phiên web                      |
  |   /api/v1/* : token app, đồng bộ, hồ sơ, thiết bị, xuất/xóa dữ liệu                  |
  |   D1 (SQLite, vùng APAC): users, devices, refresh_tokens, records, audit_log         |
  +-----------------------------------------------------------------------------------+
        ^ HTTPS + Bearer (app)                         ^ cookie __Host- (trình duyệt)
        |                                              |
  +-----+----------------------------+          +------+-----------------------------+
  | apps/app (Flutter)               |          | apps/web /do/                      |
  | Android iOS Windows macOS Linux  |          | AudioWorklet -> WASM (dsp-core)    |
  | micro -> sounddb_dsp (Dart)      |          +------------------------------------+
  | SQLite cục bộ, kho bí mật OS     |
  +----------------------------------+
        lõi DSP: packages/dsp-core (Rust, tham chiếu) == packages/dsp-dart (Dart), kiểm bằng conformance/vectors.json
```

## 2. Tech stack và lý do

| Thành phần | Chọn | Mức (LANGUAGE_SELECTION.md) | Đã cân nhắc |
| --- | --- | --- | --- |
| Lõi DSP | Rust | ⭐ (kỹ thuật, an toàn bộ nhớ) | C++ (kém an toàn bộ nhớ), làm thẳng bằng Dart/TS (không có bản tham chiếu chung) |
| App 5 nền tảng | Dart + Flutter | ⭐ đa nền tảng; ✅ Flutter Desktop "khi đã dùng Flutter cho di động" | Swift + Kotlin (2-3 mã nguồn), React Native (desktop yếu), Tauri (không có di động) |
| Website | Astro + TypeScript, trang tĩnh | ✅ (tĩnh) - cùng khung với các site con của hệ | Next.js (SSR thừa cho trang tĩnh, phải trả Workers cho mỗi lượt xem) |
| Máy chủ | TypeScript trên Cloudflare Workers + D1, Hono | ⭐ hàm biên | Node/Render (ngủ đông 15 phút, 750 giờ/tháng dùng chung cả tài khoản), Supabase (thêm một nhà cung cấp) |
| Xác thực | RP OIDC của tsudev.com | bắt buộc (AUTH_AND_ACCOUNT.md mục 2) | Kho người dùng riêng - bị cấm cho hạng A/B |

Vì sao app dùng bản Dart mà không gọi Rust qua FFI: [ADR-0002](adr/0002-loi-dsp-rust-tham-chieu-ban-dart-cho-app.md).
Vì sao đăng nhập đi qua máy chủ Sound Db: [ADR-0003](adr/0003-dang-nhap-qua-may-chu-sound-db.md).
Vì sao đồng bộ "ghi sau thắng" theo `rev`: [ADR-0004](adr/0004-dong-bo-ghi-sau-thang-theo-rev.md).

## 3. Phân loại dữ liệu (SECURITY_BASELINE.md mục 2)

| Dữ liệu | Mức | Ở đâu | Ghi chú |
| --- | --- | --- | --- |
| Âm thanh thô | - | KHÔNG lưu, không gửi | chỉ trong bộ nhớ của thiết bị |
| Phiên đo (tóm tắt, chuỗi LAeq/giây, phổ 1/3 octave), hồ sơ hiệu chuẩn | D2 | SQLite cục bộ; D1 khi đăng nhập | không vị trí |
| Danh tính (sub, email, tên, ảnh) | D2 | D1 `users` | lấy từ userinfo của tsudev.com |
| Refresh token, phiên web | D2 bí mật | chỉ SHA-256 trên D1; bản gốc trong kho bí mật OS / cookie HttpOnly | |
| Nhật ký bảo mật | D1 | D1 `audit_log` | IP băm có muối, giữ 365 ngày |

## 4. Hạn mức đang dùng

| Dịch vụ | Gói | Hạn mức | Ước lượng dùng | Cập nhật |
| --- | --- | --- | --- | --- |
| Cloudflare Workers | Free | 100.000 yêu cầu/ngày | tệp tĩnh không tính; API ~ (số người × vài lượt đồng bộ/ngày) | 17/11/2026 |
| Cloudflare D1 | Free | 5 GB, 5 triệu lượt đọc hàng/ngày | phiên đo ~ 60 KB ⇒ ~80.000 phiên/5 GB | 17/11/2026 |
| GitHub Actions | Public | không giới hạn phút | CI + build 5 nền tảng | 17/11/2026 |

Trả lời 6 câu (FREE_TIER_STACK.md mục 4) cho Workers + D1: (1) hệ chưa có kho đồng bộ cho app đo; (2) như bảng;
(3) D1 chọn vùng `apac`; (4) dữ liệu là SQLite chuẩn, `wrangler d1 export` ra SQL, chuyển sang Turso/Postgres
trong một ngày; (5) D2; (6) tài khoản Cloudflare của chủ dự án, `SESSION_SECRET` xoay bằng `wrangler secret put`
(xoay = mọi access token cũ hết hiệu lực, refresh token vẫn sống).

## 5. Luồng chính

- **Đo**: micro (PCM16, 48 kHz, tắt AGC/khử vọng/khử ồn; Android `UNPROCESSED`) → `Engine` (Dart) → giao diện ~20
  khung/giây. Không có gì rời thiết bị.
- **Lưu**: "Lưu phiên đo" ⇒ bản ghi `dirty` trong SQLite ⇒ đồng bộ nếu đã đăng nhập và bật tự đồng bộ.
- **Đồng bộ**: đẩy bản `dirty` (≤ 50/lượt) → máy chủ áp ghi sau thắng, cấp `rev`; kéo `rev > con trỏ`.
- **Đăng nhập app**: ADR-0003.

## 6. Mô hình mối đe dọa

| Mối đe dọa | Biện pháp |
| --- | --- |
| Đánh cắp mã đăng nhập ở đích quay về (app khác giành scheme) | PKCE: mã vô dụng nếu không có `code_verifier` chỉ app gốc giữ |
| CSRF đăng nhập / cố định phiên (gửi đường callback cho nạn nhân) | `state` gắn với trình duyệt qua cookie `__Host-sdb_login`, xóa khi đọc |
| Open redirect | Đích app khớp tuyệt đối danh sách; `return_to` web chỉ đường tương đối cùng gốc |
| Token bị trộm khỏi máy | Refresh trong kho bí mật OS; xoay vòng + phát hiện dùng lại ⇒ thu hồi thiết bị; người dùng thu hồi từ web |
| CSRF trên web | SameSite=Lax + kiểm `Origin` + header `X-Sdb-Csrf` cho mọi lệnh ghi |
| XSS trên web | CSP không inline, dữ liệu máy chủ chỉ gán qua `textContent` |
| Đọc dữ liệu người khác (IDOR) | Mọi truy vấn lọc `user_id` từ token; test "cô lập người dùng" |
| Lạm dụng/DoS API | Giới hạn tần suất D1, trần kích thước gói và từng bản ghi, lược đồ zod `.strict()` |
| Chuỗi cung ứng | Phiên bản ghim, Dependabot, CodeQL, gitleaks (binary ghim sha256), chứng thực nguồn gốc bản build |
