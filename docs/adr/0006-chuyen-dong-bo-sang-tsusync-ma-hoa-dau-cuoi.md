# ADR-0006: Chuyển đồng bộ đám mây sang TsuDEV Sync (tsusync) - mã hoá đầu cuối

- **Trạng thái**: ĐỀ XUẤT (chờ chủ dự án duyệt; điều kiện tiên quyết ở mục 4.1 chưa đủ)
- **Ngày**: 20/11/2026
- **Người đề xuất**: agent-sound (phiên `sound-db-67`)
- **Thay thế khi chấp nhận**: phần lưu trữ của ADR-0004 (bản ghi bản rõ trên D1 Sound Db) và ADR-0005 mục 2 (gate
  402 ở máy chủ Sound Db), mục 6 (xoá có xác minh ở `src/pro/purge.ts`). ADR-0003 (đăng nhập qua máy chủ Sound Db)
  GIỮ NGUYÊN.
- **Hợp đồng**: tsudev-standards v4.1.0 `PRODUCT_POLICY.md` mục 7.1 (N3: dữ liệu đồng bộ mã hoá đầu cuối), 7.2, 7.4;
  tsusync ADR-0001 (API), ADR-0002 (xoá có xác minh, JWS tươi, DPoP), ADR-0003 (khuôn bản mã `TS 01`).
- **Phiếu kế hoạch**: `logs/handover/20261120-E2E1_ke-hoach-chuyen-dong-bo-sang-tsusync.md`.

## 1. Bối cảnh

- Bản ghi đồng bộ của người dùng TsuDEV Pro (tóm tắt phiên đo, chuỗi LAeq/giây, phổ 1/3 octave, hồ sơ hiệu chuẩn) đang
  nằm **bản rõ** trong D1 của Sound Db - lệch PRODUCT_POLICY 7.1 N3, đã ghi ở AGENTS.md B.4.
- Lý do lúc đầu (ADR-0005 mục 3): bảng điều khiển web đọc và tìm kiếm dữ liệu ở máy chủ.
- tsusync (repo `tsudev-org/tsusync`) đã có: máy chủ chỉ giữ bản mã, kiểm Pro bằng JWS quyền lợi, xoá có xác minh với
  tsudev.com, thư viện Dart `tsusync` + TypeScript `@tsudev/sync` qua vector đối chiếu chéo. **Chưa triển khai**.
- Production Sound Db ngày 20/11/2026: **0 người dùng** trong D1 (đo bằng `wrangler d1 execute`) ⇒ chưa có bản rõ thật
  nào phải chuyển; chuyển càng sớm càng rẻ.

## 2. Các phương án

| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. Giữ máy chủ Sound Db, mã hoá payload phía app (khuôn `TS 01`), D1 Sound Db chỉ giữ bản mã | Ít thay đổi hạ tầng | Lặp lại phần kiểm Pro, hạn mức, xoá có xác minh mà tsusync đã làm và đã test; hai nơi giữ bản mã |
| **B. Chuyển hẳn bản ghi sang tsusync** (không gian tên `sounddb`), máy chủ Sound Db chỉ còn đăng nhập, quan hệ RP, quản lý thiết bị | Một chỗ kiểm Pro/hạn mức/xoá dùng chung toàn hệ; máy chủ Sound Db không còn dữ liệu đo | Phụ thuộc tsusync được triển khai; web phải giải mã trong trình duyệt |
| C. App tự đăng nhập tsudev (client OIDC native) và gọi thẳng tsusync | Bỏ máy chủ trung gian khỏi đường lấy JWS | Đảo ngược ADR-0003 (token mờ, chưa có client native) - việc lớn, không cần cho E2E |

## 3. Quyết định (khi được duyệt)

Chọn **B**.

1. **JWS cho tsusync lấy qua máy chủ Sound Db** (giữ ADR-0003): app (và trang web đã đăng nhập) gọi
   `GET /api/v1/me/entitlements` như hiện nay; JWS trả về là JWS gốc tsudev.com ký qua kênh RP, `aud` = `sounddb` =
   không gian tên tsusync. App tự kiểm chữ ký (`tsudev_ui`), rồi gửi `Authorization: Bearer <jws>` tới
   `https://sync.tsudev.com`. tsusync đòi `iat` ≤ 24 giờ ⇒ máy chủ Sound Db làm mới JWS từ tsudev.com khi JWS trong đệm
   đã quá **12 giờ** (thay vì 24 giờ như đệm quyền lợi hiện tại).
   - DPoP (tsusync ADR-0002 lộ trình bước 2): cần tsudev.com cấp `cnf.jkt` qua **kênh RP** theo khoá thiết bị app gửi
     lên (máy chủ Sound Db chuyển thumbprint như đang chuyển `X-Tsu-Installation`). Chưa có thì dùng JWS thường - đúng
     bước 1 của lộ trình.
2. **Khoá**: mật khẩu đồng bộ riêng (≥ 10 code point sau NFKC, tsusync ADR-0003 mục 2.1), đặt ở lần đầu bật đồng bộ
   Pro trên một thiết bị, nhập lại trên mỗi thiết bị mới. Tham số khoá (không bí mật: salt, ops, mem, mã kiểm) lưu ở
   **máy chủ Sound Db** (`GET/PUT /api/v1/me/sync-keys`, một dòng/tài khoản) - không đặt vào tsusync để không phải sửa
   luật `invalid_payload` của tsusync. Khoá dữ liệu chỉ ở kho bí mật của hệ điều hành (app) / bộ nhớ phiên (web).
   - **Quên mật khẩu = bản sao đám mây không đọc được.** Dữ liệu trên thiết bị không bị ảnh hưởng; "Đặt lại mật khẩu
     đồng bộ" = xoá bản sao đám mây (`DELETE /v1/account`) rồi đẩy lại từ thiết bị đang có dữ liệu. Nói rõ trên màn
     đặt mật khẩu.
3. **Bản ghi**: `id` tsusync = `s.<uuid>` (phiên đo), `c.<uuid>` (hiệu chuẩn) - uuid ngẫu nhiên, không chứa bản rõ.
   Payload = `TS 01` loại bản ghi của JSON hiện có (`MeasurementSession.toData()`, `CalibrationProfile.toData()`).
   Ghi sau thắng như ADR-0004 (không gửi `base_rev`); con trỏ kéo = `rev` của tsusync.
4. **Web** (`/bang-dieu-khien/`): giải mã trong trình duyệt bằng `@tsudev/sync` (libsodium WASM): nhập mật khẩu đồng
   bộ ⇒ kéo, giải mã, tìm theo tên **phía máy khách**; xoá phiên = bia mộ tsusync; "Tải toàn bộ dữ liệu (JSON)" = xuất
   bản đã giải mã từ trình duyệt. CSP trang này thêm `connect-src https://sync.tsudev.com` và `'wasm-unsafe-eval'`
   (Worker đặt, như `/do/`).
5. **Máy chủ Sound Db** sau khi chuyển: còn đăng nhập (OIDC RP), làm mới quyền lợi + chuyển JWS, thiết bị + nhật ký bảo
   mật, tham số khoá. `POST /api/v1/sync/push`, `GET /api/v1/sync/pull`, `/api/v1/sessions*` ⇒ `410 moved_to_tsusync`.
   Bảng `records` bị xoá bằng migration mới (migration đã áp dụng là bất biến). `src/pro/purge.ts` bỏ - tsusync tự xoá
   có xác minh (tsusync ADR-0002). Xoá tài khoản Sound Db (`DELETE /api/v1/me`) gọi thêm `DELETE /v1/account` của
   tsusync bằng JWS của chính người dùng.
6. **Bản miễn phí không đổi**: không đăng nhập ⇒ 0 yêu cầu mạng; đăng nhập mà không Pro ⇒ không gọi tsusync.

## 4. Hệ quả

### 4.1. Điều kiện tiên quyết (chưa đủ ngày 20/11/2026)

- [ ] tsusync triển khai lên `sync.tsudev.com`, `NAMESPACES` có `sounddb` (cần chủ dự án duyệt - tsusync README mục
  Triển khai).
- [ ] Thư viện Dart `tsusync` + `@tsudev/sync` có thẻ phát hành để ghim (hiện ghim theo commit).
- [ ] Chủ dự án duyệt ADR này (đổi trạng thái sang ĐÃ CHẤP NHẬN).

### 4.2. Tích cực

- Máy chủ Sound Db không còn đọc được dữ liệu đo của ai ⇒ đóng lệch N3, gỡ dòng AGENTS.md B.4.
- Bớt mã tự viết: gate 402, hạn mức, xoá có xác minh dùng chung tsusync (đã test ở repo đó).

### 4.3. Tiêu cực và chi phí

- Người dùng phải nhớ thêm một mật khẩu đồng bộ; quên ⇒ mất bản sao đám mây (không mất dữ liệu trên thiết bị).
- Web: tìm kiếm/phân trang làm trong trình duyệt - chậm dần khi lịch sử rất lớn (hạn mức 100 MiB/tài khoản giới hạn
  trần). Argon2id 64 MiB trên điện thoại yếu mất 1-3 giây mỗi lần mở khoá.
- Thêm một phụ thuộc vận hành (tsusync); tsusync gặp sự cố ⇒ "Chưa đồng bộ", app vẫn chạy cục bộ đủ.
- JWS là bearer token tới khi có DPoP: lộ JWS ⇒ đọc được BẢN MÃ (không đọc được nội dung).

### 4.4. Việc phát sinh

Theo phiếu `20261120-E2E1` (các bước E1-E5).
