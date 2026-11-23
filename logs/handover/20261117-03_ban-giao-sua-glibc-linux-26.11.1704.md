# PHIẾU BÀN GIAO - Sửa gói Linux (glibc), bản 26.11.1704, merge linux-packages #30 (agent-sound)

- **Mã phiếu**: 20261117-03
- **Từ**: agent-sound - **Đến**: phiên kế tiếp của repo `sound-db` / chủ dự án (mục 3)
- **Thời điểm**: 17:55 17/11/2026
- **Trạng thái**: MỞ
- **Nhánh git**: `main` sạch, đã đẩy. Không nhánh dở. `logs/LOCKS.md` trống, không tiến trình nền.

## 1. Việc đã làm xong

- Xác minh nguyên nhân PR linux-packages #30 hỏng debian:12/ubuntu:22.04 (run 44023209494):
  `libflutter_secure_storage_linux_plugin.so` đòi `GLIBC_2.38` vì job `linux` dựng trên ubuntu-24.04
  (deb khai `libc6 (>= 2.34)`). Arm64 đạt chỉ vì không có bản arm64 để cài thử thật.
- sound-db #2: job `linux` của `release.yml` dựng trên `ubuntu-22.04` + bước chặn hồi quy (lỗi nếu tệp trong bundle
  đòi GLIBC > 2.34). Tag `v26.11.1703` HỎNG ở bước apt (runner 22.04 có sẵn `libunwind-14-dev` xung đột
  `libunwind-dev`) - KHÔNG có Release 1703, tag để nguyên.
- sound-db #3: gỡ `libunwind-14-dev` trước khi cài. **v26.11.1704** phát hành đủ (Windows/macOS/Linux, SHA256SUMS,
  chứng thực); log dựng: "GLIBC cao nhất: GLIBC_2.34".
- Web triển khai bằng `npx wrangler deploy` (version 3031af53): /tai-ve/ trỏ 26.11.1704.
- linux-packages #30: chạy lại, 12/12 check đạt (cả debian:12, ubuntu:22.04 với 26.11.1704) ⇒ đã merge (squash).

## 2. Việc dang dở + bước tiếp theo CỤ THỂ

- [ ] Sau khi chủ dự án duyệt `xuat-ban` (mục 3.1) và kho có gói: chuyển `apt`,`rpm` từ `planned` sang `channels`
  trong `packaging/package.json`, thêm lệnh vào `LENH` của `apps/web/src/pages/tai-ve.astro`, dựng web + deploy.
  Kiểm: `curl -s https://pkg.tsudev.com/... | grep tsudev-sound-db` (xem README của linux-packages cho đường dẫn).
- [ ] Sau khi có client OIDC (3.2): đăng nhập thử web + app, nghiệm thu đồng bộ hai thiết bị.
- [ ] Logo riêng: đề xuất cho chủ dự án duyệt (`BRAND_ASSETS.md` mục 15).

## 3. Việc của chủ dự án (👤/⛔) - lệnh soạn sẵn

1. 👤 Duyệt xuất bản kho Linux (run `xuat-ban` 44070139518, Environment `packages` id 26928270657):
   ```bash
   gh api -X POST repos/tsudev-org/linux-packages/actions/runs/44070139518/pending_deployments \
     -F 'environment_ids[]=26928270657' -f state=approved -f comment='Duyet Sound Db 26.11.1704'
   ```
2. 👤 Client OIDC `sounddb`: chạy SQL trong phiếu tsudev `20261117-SD1` (bản gốc `logs/handover/20261117-01_*`).
3. 👤 Secret Cloudflare cho Deploy, rồi bỏ chú thích khối `push` trong `.github/workflows/deploy.yml`:
   ```bash
   # (Đã làm 17/11. Từ 23/11 - phiếu SEC1: KHÔNG dán token; dùng
   #  `tsu-nhan-bi-mat --stdout | gh secret set ...`, xem docs/DEPLOYMENT.md mục 2.)
   gh secret set CLOUDFLARE_API_TOKEN  --env production --repo tsudev-org/sound-db   # quyền Workers + D1
   gh secret set CLOUDFLARE_ACCOUNT_ID --env production --repo tsudev-org/sound-db
   ```
4. 👤 Khóa ký Android (Environment `release`), rồi tag bản mới:
   ```bash
   keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000
   base64 -w0 upload.jks | gh secret set ANDROID_KEYSTORE_BASE64 --env release --repo tsudev-org/sound-db
   gh secret set ANDROID_KEYSTORE_PASSWORD --env release --repo tsudev-org/sound-db
   gh secret set ANDROID_KEY_ALIAS --env release --repo tsudev-org/sound-db --body upload
   gh secret set ANDROID_KEY_PASSWORD --env release --repo tsudev-org/sound-db
   ```
   Cất `upload.jks` + mật khẩu ngoài máy (mất khóa = không cập nhật được app).
5. 👤 Required reviewers cho `release` và `production` (người duyệt `tsudev-tsudev`, id 291851597):
   ```bash
   for e in release production; do
     echo '{"reviewers":[{"type":"User","id":291851597}]}' | gh api -X PUT repos/tsudev-org/sound-db/environments/$e --input -
   done
   ```
6. ⛔ scoop-bucket #17: chủ sở hữu `nguyentrangtinhsu` Approve. Không merge bằng `--admin`.
7. 👤 winget `tsudev.SoundDb`: PR vào microsoft/winget-pkgs (bộ phân loại từng chặn).

## 4. Cập nhật cuối phiên (18:20 17/11/2026)

- Chủ dự án ủy quyền tự làm mọi bước còn lại; sẽ đưa token (Cloudflare, GitHub...) qua một thư mục ngoài repo,
  dùng xong thu hồi. Phiên mới: HỎI đường dẫn thư mục, chỉ nạp vào biến môi trường, không in/ghi token.
- Lúc 18:20: run `xuat-ban` 44070139518 vẫn `waiting` (run 44070780864 xếp hàng sau), scoop-bucket #17 vẫn
  `BLOCKED` không có review - chủ dự án báo đã duyệt nhưng GitHub chưa ghi nhận ⇒ kiểm lại đầu phiên:
  `gh run list --repo tsudev-org/linux-packages --workflow xuat-ban -L3`; `gh pr view 17 --repo tsudev-org/scoop-bucket`.
- Agent tự duyệt Environment bị bộ phân loại quyền chặn ("Undermining Oversight") ⇒ cổng duyệt luôn là việc người.
- `/auth/web/start` → tsudev trả 400 `invalid_client`: client OIDC `sounddb` CHƯA có (phiếu tsudev `20261117-SD1`;
  repo tsudev có phiên riêng ⇒ nhắn qua ListAgents/SendMessage, không tự sửa DB).
- Khi có token Cloudflare: secret Environment `production` + bật `push` ở `deploy.yml`. Khóa Android: agent tạo,
  để `upload.jks` + mật khẩu trong thư mục chủ dự án chỉ định. Required reviewers làm SAU các bản phát hành.
- Kiểm thử trình duyệt toàn bộ (Playwright + axe) + luồng đăng nhập/đồng bộ khi có client OIDC.

**Cập nhật 19:30 17/11/2026:** chủ dự án đã duyệt; scoop-bucket #17 chạy lại cổng bản quyền ⇒ đạt, đã merge,
excavator chạy tay đạt (Scoop 26.11.1704); Homebrew `cap-nhat` chạy tay ⇒ 26.11.1704; `xuat-ban` xong, kho apt/rpm
có `tsudev-sound-db` 26.11.1704-1. `/tai-ve/` đọc `pkg.tsudev.com/catalog.json` lúc build để hiện lệnh APT/DNF;
`packaging/package.json` chuyển apt, rpm sang `channels`. Test máy chủ ghim `PUBLIC_ORIGIN` (trước đó `.dev.vars`
cục bộ làm 2 test hỏng ở máy dev). Mục 2 gạch đầu tiên và mục 3.1, 3.6 ĐÃ XONG.

## 5. Cảnh báo

- Tag `v26.11.1703` không có Release - đừng dùng lại số này.
- Runner `ubuntu-22.04`: `libunwind-14-dev` cài sẵn xung đột `libunwind-dev` (đã xử lý trong `release.yml`).
- Máy dev quá tải (CPU/RAM gần 100%) làm `fetch` lúc build Astro hết giờ - dựng lại; CI không bị.
- Sau `wrangler deploy`, trang tĩnh có thể còn bản cũ ~1 phút do cache cạnh (`cf-cache-status: HIT`).
- `pgrep -f "wrangler dev"` khớp cả chính shell đang chạy lệnh ⇒ báo nhầm; dùng `pgrep -x workerd` hoặc lọc PID shell.
- Chưa xử lý: `~/.config/tsudev/cloudflare.env` quyền 644 (của phiên khác) - nên `chmod 600` hoặc thu hồi.

## 6. Trạng thái cổng kiểm

CI `main` xanh (PR #2, #3: 10/10 check); Release 26.11.1704 7/7 job đạt; linux-packages #30 12/12 đạt.
