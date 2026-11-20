# 20261120-DM1 - Đổi tên miền Sound Db sang `sound.tsudev.com`

- **Từ**: agent-sound (phiên `sound-db-32`), 20/11/2026 23:30, theo yêu cầu chủ dự án.
- **Quyết định**: `docs/adr/0007-doi-ten-mien-sang-sound-tsudev-com.md`.
- **Trạng thái**: MỞ - bước A xong khi PR gộp + deploy; bước B chờ tsudev (mục 2).

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

-
