# PHIẾU YÊU CẦU SEC1 - Nhận token/secret qua clipboard (sound-db)

- **Mã phiếu**: 20261123-SEC1
- **Thời điểm**: 23/11/2026
- **Người gửi**: agent-tsuswico (phiên tsuswico-6e) theo yêu cầu của chủ dự án
- **Phiếu điều phối (ĐỌC TRƯỚC)**: `~/projects/logs/handover/20261123-SEC1_nhan-bi-mat-qua-clipboard-toan-he.md`
- **Trạng thái**: ĐÓNG (24/11/2026, sound-db-c9)

## 1. Quy tắc áp dụng ngay cho agent của repo này

- KHÔNG đề nghị chủ dự án dán token/secret vào chat, tệp hay lệnh `!`. Lỡ dán vào chat ⇒ coi là đã lộ, đề nghị thay.
- Nhận bí mật: chạy `tsu-nhan-bi-mat ...` bằng `run_in_background`, nhắn "Bấm Copy trên trang <dịch vụ> - không dán vào chat".
  Ưu tiên `--stdout | <lệnh đích>`; cần giữ ⇒ `--luu ~/.config/tsudev/<ten>.env` (chmod 600, ngoài repo).
- KHÔNG in giá trị bí mật (`cat .env`, `sed`…); chỉ in tên biến/độ dài/kết quả kiểm tra.
- Cần người dán vào dashboard ⇒ `tsu-nhan-bi-mat --dua-vao-clipboard <tệp>` rồi `--xoa-lich-su <tệp>`.
- Lịch sử Win+V trên máy đang BẬT ⇒ luôn để công cụ xoá mục khỏi lịch sử.

## 2. Việc cần làm

1. Rà tài liệu/hướng dẫn của repo (README thiết lập, `docs/`, `logs/STATE.md`, phiếu cũ còn mở) - chỗ nào bảo dán token
   vào chat/.env bằng tay ⇒ sửa theo phiếu điều phối mục 2-3.
2. Kiểm `.gitignore` có `.env*` (trừ `.env.example`); gitleaks/push protection theo SECURITY_BASELINE.
3. Liệt kê TÊN các bí mật repo dùng + nơi lưu (GitHub Actions secret / Cloudflare / Vercel / Render / `~/.config/tsudev/`)
   + phạm vi quyền vào mục 3 dưới (không ghi giá trị). Cái nào từng lộ trong chat/log ⇒ báo chủ dự án thay.
4. Ghi AKB của repo "áp dụng SEC1", đổi Trạng thái → ĐÓNG.

## 3. Bí mật của repo (agent điền - CHỈ TÊN)

| Tên | Nơi lưu | Phạm vi | Ghi chú |
| --- | --- | --- | --- |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | GitHub Environment `production`; bản tại máy `~/.config/tsudev/cloudflare-sounddb.env` (600, 24/11) | Workers Scripts Edit, Workers Routes Edit + DNS Edit (zone tsudev.com), D1 Edit - chỉ job Deploy | 24/11: token cũ hết quyền (Deploy `7403`, bản cũ tại máy `cloudflare.env` lỗi 10000 - bỏ) ⇒ token mới nhận qua `tsu-nhan-bi-mat` (`--kiem` đòi đọc được D1 `sound-db`), đưa vào GitHub qua stdin; chưa từng xuất hiện trong chat |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | GitHub Environment `release`; gốc `~/.config/tsudev/android/` (600) | Ký APK - chỉ job phát hành | Mất khoá = không cập nhật được app |
| `VT_API_KEY` | Secret cấp Organization `tsudev-org` | Quét VirusTotal khi phát hành | Dùng chung toàn hệ |
| `SESSION_SECRET`, `IP_HASH_SALT` | Secret Worker `sound-db` (Cloudflare) | Ký access token app / băm IP | Sinh bằng `openssl rand`, không đi qua người |
| `RP_PRIVATE_JWK` | Secret Worker `sound-db`; gốc `~/.config/tsudev/sounddb/rp-private.jwk` (600) | Kênh RP quyền lợi Pro tới tsudev | Sinh tại máy, không đi qua chat |
| (tại máy dev) `services/sync-api/.dev.vars` | Không commit (`.gitignore` dòng `.dev.vars`) | Chỉ `wrangler dev` | Giá trị ngẫu nhiên riêng, không dùng bí mật production |

## 4. Kết quả (24/11/2026)

- Mục 2.1: sửa `docs/DEPLOYMENT.md` mục 2 (nhận token bằng `tsu-nhan-bi-mat`), `README.md` (`.dev.vars` sinh bằng
  `openssl rand`), phiếu cũ `20261117-03` (lệnh `gh secret set ... # dán token` ghi chú SEC1). Không chỗ nào khác
  hướng dẫn dán bí mật (rà `README`, `docs/`, `CONTRIBUTING`, `logs/`).
- Mục 2.2: `.gitignore` có `.env`, `.env.*` (trừ `*.example`/`*.sample`) + `.dev.vars`; gitleaks binary ghim trong CI;
  secret scanning + push protection BẬT (`gh api`, 24/11).
- Mục 2.3: bảng trên. Phiếu, STATE và AKB của sound-db không ghi nhận bí mật nào từng bị dán vào chat/log.
