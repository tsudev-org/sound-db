# Triển khai - Sound Db

## 1. Thành phần production

| Thành phần | Ở đâu | Lệnh |
| --- | --- | --- |
| Website + API | Cloudflare Worker `sound-db`, Custom Domain `sound.tsudev.com` | `npm run deploy` |
| Cơ sở dữ liệu | Cloudflare D1 `sound-db`, vùng `apac` | migration tự áp trong `deploy` |
| App | GitHub Releases (`.github/workflows/release.yml`) | đẩy tag `v<phiên bản>` |

## 2. Lần đầu (chủ dự án hoặc agent có token)

```bash
npx wrangler d1 create sound-db --location apac          # chép database_id vào services/sync-api/wrangler.jsonc
openssl rand -base64 48 | npx wrangler secret put SESSION_SECRET --config services/sync-api/wrangler.jsonc
openssl rand -base64 24 | npx wrangler secret put IP_HASH_SALT --config services/sync-api/wrangler.jsonc
npm run deploy
```

Token Cloudflare cần quyền: Workers Scripts Edit, Workers Routes Edit (zone tsudev.com), D1 Edit, DNS Edit (zone
tsudev.com - để Custom Domain tự tạo bản ghi). Đặt bằng `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` trong shell,
không ghi vào tệp.

Đăng ký client OIDC ở TsuDEV (chỉ OWNER, chèn bảng - TsuDEV `docs/auth.md` mục 8):

```sql
INSERT INTO "OAuthClient" (id, name, "redirectUris", "postLogoutRedirectUris", scopes)
VALUES ('sounddb', 'Sound Db', ARRAY['https://sound.tsudev.com/auth/callback', 'https://sounddb.tsudev.com/auth/callback'], ARRAY['https://sound.tsudev.com/'], ARRAY['profile', 'email']);
```

## 3. Nghiệm thu sau mỗi lần triển khai

```bash
curl -s https://sound.tsudev.com/api/v1/health                     # {"ok":true,...}
curl -sI https://sound.tsudev.com/do/ | grep -i content-security   # có 'wasm-unsafe-eval', đúng MỘT dòng
curl -sI https://sound.tsudev.com/ | grep -i content-security      # KHÔNG có wasm-unsafe-eval
curl -s -o /dev/null -w '%{http_code}\n' https://sound.tsudev.com/api/v1/me   # 401
curl -sI https://sound.tsudev.com/auth/web/start | grep -i '^location: https://tsudev'   # (sau khi đăng ký client)
```

Mã 200 không chứng minh trang có nội dung: mở `/do/`, bấm Bắt đầu đo, thấy số nhảy.

## 4. Sao lưu và xoay khóa

- `npx wrangler d1 export sound-db --remote --output sound-db-$(date +%Y%m%d).sql` (dữ liệu D2: mã hoá bằng `age`
  trước khi cất).
- Xoay `SESSION_SECRET`: mọi access token cũ hết hiệu lực (app tự xoay bằng refresh token, người dùng không thấy).
- Lộ `SESSION_SECRET`: xoay NGAY + `DELETE FROM refresh_tokens;` (buộc mọi thiết bị đăng nhập lại).
