# 20261120-DM1 - Đổi tên miền Sound Db sang `sound.tsudev.com`

- **Từ**: agent-sound (phiên `sound-db-32`), 20/11/2026 23:30, theo yêu cầu chủ dự án.
- **Quyết định**: `docs/adr/0007-doi-ten-mien-sang-sound-tsudev-com.md`.
- **Trạng thái**: MỞ (chỉ còn việc ngoài repo, mục 4) - bước A + B đã deploy 20/11/2026.

## 1. Bước A (PR `feat/ten-mien-sound-tsudev-com`)

Worker gắn thêm `sound.tsudev.com`; `/auth/*` ở host phụ 307 về host chuẩn; token nhận `iss` của cả hai host. 41 test.

## 2. Chặn bước B

| # | Việc | Ai |
| --- | --- | --- |
| D1 | Thêm `https://sound.tsudev.com/auth/callback` vào `OAuthClient.redirectUris` của client `sounddb` (GIỮ redirect cũ) | phiên tsudev - phiếu `tsudev/logs/handover/20261120-SDB2_*` |

Kiểm trước khi làm bước B: `curl -s -o /dev/null -w '%{redirect_url}' 'https://tsudev.com/oidc/auth?client_id=sounddb&response_type=code&scope=openid&redirect_uri=https%3A%2F%2Fsound.tsudev.com%2Fauth%2Fcallback&code_challenge=x&code_challenge_method=S256'`
không còn báo `invalid_redirect_uri`.

## 3. Bước B - danh sách việc

Đúng ADR-0007 mục 3 bước B (1-3). Tệp có tên cũ: `git grep -l sounddb.tsudev.com` (35 tệp lúc 20/11; tệp `logs/` giữ
nguyên vì là lịch sử).

## 4. Kết quả xử lý

- 20/11/2026 - `sound-db-32`: bước A PR #24 gộp + deploy; đo production: sound.tsudev.com API/trang 200, `/auth/*` 307,
  CSP còn. tsudev thêm callback mới (SDB2, 303). Bước B PR #25. Còn: tsudev SDB2 mục 1.2 (đã báo); homepage ở
  scoop-bucket/homebrew-tap/linux-packages (tên cũ vẫn chạy - không gấp).
- 20/11/2026 - `sound-db-32`: bước B PR #25 gộp + deploy (run 44777077441 đạt, kể cả bước kiểm tên cũ). Đo production:
  sound.tsudev.com `/auth/web/start` → tsudev `/oidc/auth` với `redirect_uri` tên mới → 303 `/oidc/interaction`;
  sounddb.tsudev.com health 200, `/auth/web/start` 307 → tên mới, `theme.js` có lệnh chuyển; canonical tên mới. Đã nhắn
  tsudev-0a làm SDB2 mục 1.2.
