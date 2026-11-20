# 20261120-E2E1 - sound-db: chuyển đồng bộ đám mây sang TsuDEV Sync (mã hoá đầu cuối)

- **Người lập**: phiên `sound-db-67` (agent-sound), 20/11/2026.
- **Quyết định kiến trúc**: `docs/adr/0006-chuyen-dong-bo-sang-tsusync-ma-hoa-dau-cuoi.md` (ĐỀ XUẤT).
- **Hợp đồng**: tsudev-standards v4.1.0 `PRODUCT_POLICY.md` 7.1 (N3), 7.2, 7.4; tsusync ADR-0001/0002/0003.
- **Trạng thái**: MỞ - chặn bởi mục 1 (👤 + tsusync). Không bắt đầu E1 khi mục 1 chưa đủ.

## 1. Điều kiện tiên quyết (chặn)

| # | Việc | Ai | Ghi chú |
| --- | --- | --- | --- |
| P1 | Duyệt ADR-0006 (phương án B, mật khẩu đồng bộ riêng, tham số khoá ở máy chủ Sound Db) | 👤 chủ dự án | Đổi trạng thái ADR sang ĐÃ CHẤP NHẬN |
| P2 | Triển khai tsusync lên `sync.tsudev.com`, `NAMESPACES` gồm `sounddb`, `QUOTAS` mặc định (100 MiB + 1 GiB, Sound Db không dùng tệp) | 👤 duyệt + phiên tsusync | tsusync README mục Triển khai: D1 `tsusync`, R2, secret `RP_PRIVATE_JWK` + `SUB_ENC_KEY`, route |
| P3 | Thẻ phát hành cho Dart `tsusync` và `@tsudev/sync` để ghim | phiên tsusync | Hiện chỉ ghim theo commit |
| P4 | (Không chặn, lộ trình DPoP) kênh RP của tsudev.com nhận thumbprint khoá thiết bị và cấp JWS có `cnf.jkt` | phiên tsudev | tsusync ADR-0002 mục 3.2 bước 2 |

Phiên sau: khi P1-P3 đủ, gửi phiếu yêu cầu tương ứng sang `tsusync`/`tsudev` theo `~/.claude/CLAUDE.md` (ListAgents →
SendMessage nếu repo đó có phiên đang chạy).

## 2. Các bước (mỗi bước một PR, CI xanh mới gộp)

### E1 - Máy chủ Sound Db: tham số khoá + JWS tươi

- Migration mới `0003_sync_keys.sql`: bảng `sync_keys (user_id PK, params TEXT, updated_at)`.
- `GET /api/v1/me/sync-keys` (null nếu chưa đặt), `PUT` (kiểm khuôn tsusync ADR-0003 mục 2.1-4: `v`=1, `alg`=argon2id13,
  salt 16 B, ops 2-16, mem 19 MiB-1 GiB, check 16 B; CSRF như mọi lệnh ghi).
- `getEntitlement`: chuyển JWS cho app/web chỉ khi `iat` ≤ 12 giờ, cũ hơn ⇒ làm mới từ kênh RP (giữ đệm quyền lợi
  24 giờ cho việc kiểm Pro).
- Test: khuôn tham số sai bị từ chối; JWS 13 giờ tuổi bị làm mới; không Pro vẫn đọc/ghi được tham số khoá (để đặt lại).

### E2 - App: lớp đồng bộ tsusync

- `pubspec.yaml`: `tsusync` (git, `path: clients/dart`, ghim thẻ), `sodium`/libsodium theo yêu cầu của thư viện.
- `lib/sync/sync_service.dart`: thay push/pull máy chủ Sound Db bằng `SyncClient` tsusync; `id` = `s.<uuid>`/`c.<uuid>`,
  payload `TS 01`; con trỏ = `rev` tsusync; `402` ⇒ dừng, hiện màn Pro; `413 quota_exceeded`/`507` ⇒ "Chưa đồng bộ" kèm
  lý do; `401 stale` ⇒ làm mới JWS một lần.
- Màn **Mật khẩu đồng bộ** (lần đầu bật đồng bộ Pro / thiết bị mới): đặt (≥ 10 ký tự, nhập 2 lần) hoặc nhập; mã kiểm sai
  ⇒ báo ngay. Cảnh báo nguyên văn "Quên mật khẩu đồng bộ thì bản sao trên đám mây không đọc được; dữ liệu trên thiết bị
  vẫn còn." (vi + en trong ARB). "Đặt lại mật khẩu đồng bộ" ⇒ `DELETE /v1/account` rồi đẩy lại toàn bộ.
- Khoá dữ liệu lưu `flutter_secure_storage`; đăng xuất ⇒ xoá khoá.
- Test: vector `conformance/vectors-v1.json` của tsusync giải mã đúng; máy chủ tsusync giả (như `fake_sync_server` của
  qulythuchi) - đẩy/kéo/bia mộ/402/413; miễn phí ⇒ 0 yêu cầu tới tsusync.

### E3 - Web: bảng điều khiển giải mã trong trình duyệt

- `@tsudev/sync` (ghim thẻ) cho `/bang-dieu-khien/` + `/en/bang-dieu-khien/`; ô nhập mật khẩu đồng bộ, khoá chỉ trong
  bộ nhớ trang.
- Phiên đo: kéo + giải mã, tìm theo tên và phân trang phía máy khách (giữ `DATA_TABLE.md`: mốc 10/20/50/100/200, nhớ
  lựa chọn); xoá = bia mộ; "Tải toàn bộ dữ liệu (JSON)" = xuất bản đã giải mã.
- Worker đặt CSP riêng cho hai trang này (như `/do/`): `connect-src 'self' https://sync.tsudev.com`,
  `script-src 'self' 'wasm-unsafe-eval'`; thêm cả hai đường dẫn vào `run_worker_first`.
- Test: Playwright với tsusync giả - mật khẩu sai báo đúng, tìm kiếm, xoá, xuất; check-dist kiểm CSP trang.

### E4 - Tắt đường bản rõ trên máy chủ Sound Db

- `POST /api/v1/sync/push`, `GET /api/v1/sync/pull`, `/api/v1/sessions*`, `PATCH` phiên ⇒ `410 moved_to_tsusync`.
- Migration mới xoá bảng `records` (sau khi đo lại production: 0 bản ghi; nếu > 0 thì app của người đó đã đẩy lại sang
  tsusync ở E2 trước khi xoá - kiểm bằng truy vấn, ghi số liệu vào mục 4).
- Bỏ `src/pro/purge.ts` + test; gate 402 chỉ còn ở tsusync. `DELETE /api/v1/me` gọi thêm `DELETE /v1/account` tsusync.
- Cập nhật THREAT_MODEL, `bao-mat` (vi + en): máy chủ không đọc được dữ liệu đo.

### E5 - Đóng

- Gỡ dòng "chưa mã hoá đầu cuối" ở AGENTS.md B.4; ADR-0004/0005 ghi "được thay một phần bởi ADR-0006".
- Đo production: đẩy từ hai thiết bị, kéo chéo, web giải mã; D1 Sound Db không còn bảng `records`.

## 3. Rủi ro

- tsusync chưa có người dùng thật nào ⇒ Sound Db là sản phẩm đầu tiên: dự trù lỗi ở chính tsusync, báo ngược bằng phiếu.
- Argon2id 64 MiB trên Android cũ: đo thời gian mở khoá trong kế hoạch kiểm thử smartphone (`20261117-06`).
- Bản Play: Play Billing chưa nối (chờ tsudev B2) - không ảnh hưởng đường đồng bộ.

## 4. Kết quả xử lý (mỗi phiên ghi một dòng)

- 20/11/2026 - `sound-db-67`: lập ADR-0006 + phiếu này. Đo: production D1 `users` = 0, kênh RP/trạng thái của tsudev
  nhận khoá `sounddb` (HTTP 200). Chưa làm E1 vì P1-P3 chưa đủ.
