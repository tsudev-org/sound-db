# ADR-0007: Đổi tên miền sang `sound.tsudev.com`, giữ `sounddb.tsudev.com` vĩnh viễn cho app đã cài

- **Trạng thái**: ĐÃ CHẤP NHẬN (bước A); bước B chờ tsudev.com đăng ký callback mới
- **Ngày**: 20/11/2026
- **Người quyết định**: agent-sound, theo yêu cầu chủ dự án 20/11/2026 23:20 ("cập nhật/thay đổi subdomain ... thành
  sound.tsudev.com", ủy quyền chọn phương án)

## 1. Bối cảnh

Website + API ở `sounddb.tsudev.com` (một Worker, Workers Static Assets, ADR-0001). Tên cũ đã nằm trong: app đã cài
(Android 26.11.1705, desktop - `apiBase` biên dịch sẵn), access token (`iss`), client OIDC `sounddb` của tsudev.com
(redirect DUY NHẤT `https://sounddb.tsudev.com/auth/callback`), Scoop/Homebrew/APT, `security.txt`, thẻ ở tsudev.com/apps.
Giống quy tắc tên repo (~/.claude/CLAUDE.md): URL cũ gãy im lặng là lỗi không cổng nào bắt ⇒ tên cũ KHÔNG BAO GIỜ bỏ.

## 2. Phương án

| | Phương án | Kết luận |
| --- | --- | --- |
| A | Đổi `PUBLIC_ORIGIN` + route một lần | Loại: callback mới chưa đăng ký ⇒ đăng nhập hỏng; app cũ mất API |
| B | `run_worker_first: true`, Worker 301 trang ở host cũ | Loại: thử `wrangler dev` 20/11 - trang qua Worker mất header `_headers` (CSP) và mỗi lượt xem tốn một lượt gọi Worker |
| C | **Hai bước**: một Worker gắn cả hai tên miền; sau đó đảo host chuẩn, host cũ qua Worker chuyển hướng nhỏ | **Chọn** |

## 3. Quyết định

**Bước A (PR này)** - không đổi hành vi người dùng đang có:
- Route Custom Domain thêm `sound.tsudev.com`; `PUBLIC_ORIGIN` vẫn `https://sounddb.tsudev.com`;
  `ALIAS_ORIGINS = "https://sound.tsudev.com"` (`src/lib/hosts.ts`).
- `/auth/*` ở host phụ ⇒ 307 nguyên đường + query về host chuẩn (cookie `__Host-sdb_login`/phiên web phải cùng host với
  `redirect_uri`). Host lạ không bị chuyển.
- Access token nhận `iss` ∈ host chuẩn + host phụ ⇒ đảo host ở bước B không đăng xuất app.
- Trang tĩnh phục vụ y nguyên ở cả hai host (0 lượt gọi Worker); API chạy ở cả hai.

**Bước B (sau khi tsudev.com THÊM `https://sound.tsudev.com/auth/callback` vào client `sounddb`, GIỮ redirect cũ)**:
1. `PUBLIC_ORIGIN = https://sound.tsudev.com`, `ALIAS_ORIGINS = https://sounddb.tsudev.com`; `apps/web` `SITE`, `apiBase`
   mặc định của app, `security.txt`, `robots.txt`, `deploy.yml`, `packaging/package.json`, tài liệu ⇒ tên mới.
2. Host cũ chuyển sang Worker nhỏ `sound-db-alias` (service binding tới `sound-db`): `/api/*` chuyển tiếp nguyên
   yêu cầu; còn lại 301 sang `https://sound.tsudev.com` cùng đường + query. Gỡ custom domain cũ khỏi `sound-db` rồi gắn
   cho `sound-db-alias` (làm tay bằng wrangler có xác nhận, ghi lệnh vào phiếu).
3. Phiếu cho tsudev (thẻ tsudev.com/apps, `pkgCatalog` homepage, `build-eco-icons` logo), scoop-bucket, homebrew-tap,
   linux-packages: đổi homepage. Updater/manifest cũ vẫn chạy nhờ host cũ.

## 4. Hệ quả

- `sounddb.tsudev.com` là tên miền giữ chỗ VĨNH VIỄN: không xoá route/DNS, không dùng cho dịch vụ khác.
- Bước B làm mất phiên web đang đăng nhập (cookie gắn host) - người dùng đăng nhập lại một lần. App không bị ảnh hưởng.
