# AGENTS.md - sound-db

> **ĐỌC FILE NÀY ĐẦU TIÊN trong mọi phiên làm việc mới.**

## Phần A - Quy ước chung của hệ sinh thái (KHÔNG SỬA Ở ĐÂY)

Toàn bộ quy ước chung nằm trong bản sao chỉ-đọc tại
[`.standards/AGENTS.md`](.standards/AGENTS.md). `MUST` đọc file đó trước.

Bản quy ước repo này đang dùng: xem [`.standards-version`](.standards-version).

| Cần gì | Đọc file nào |
| --- | --- |
| Điểm vào, nguyên tắc chung | `.standards/AGENTS.md` |
| Quy trình phiên, khóa file, bàn giao | `.standards/docs/AGENT_PROTOCOL.md` |
| Bảo mật bắt buộc | `.standards/docs/SECURITY_BASELINE.md` |
| Quy tắc `.gitignore` | `.standards/docs/GITIGNORE_POLICY.md` |
| Nhánh, commit, PR, phát hành | `.standards/docs/GIT_WORKFLOW.md` |
| Đăng nhập, đăng ký, xác minh tài khoản | `.standards/docs/AUTH_AND_ACCOUNT.md` |
| Giao diện và token | `.standards/docs/DESIGN_SYSTEM.md` |
| Bảng bản ghi, bộ chọn số bản ghi | `.standards/docs/DATA_TABLE.md` |
| Logo, favicon, icon ứng dụng | `.standards/docs/BRAND_ASSETS.md` |
| tsudev.com, ảnh đại diện, trang hồ sơ | `.standards/docs/ECOSYSTEM_IDENTITY.md` |
| Cấu trúc thư mục | `.standards/docs/PROJECT_STRUCTURE.md` |
| Chọn ngôn ngữ, framework | `.standards/docs/LANGUAGE_SELECTION.md` |
| Hạ tầng 0 đồng | `.standards/docs/FREE_TIER_STACK.md` |
| Trình soạn thảo nội dung | `.standards/docs/RICH_TEXT_EDITOR.md` |
| Tìm kiếm và lọc tiếng Việt | `.standards/docs/SEARCH_AND_FILTER.md` |
| Kiểm thử và chất lượng mã | `.standards/docs/TESTING_QUALITY.md` |
| Khả năng truy cập | `.standards/docs/ACCESSIBILITY.md` |

`MUST NOT` sửa bất kỳ file nào trong `.standards/`. Cần đổi quy ước thì mở đề
xuất tại repo `tsudev-standards` theo `.standards/docs/SYNC.md` mục 1.

## Phần B - Riêng của repo này

### B.1. Repo này là gì

- **Loại**: app di động + phần mềm desktop + website + dịch vụ (monorepo, hình trạng B của `PROJECT_STRUCTURE.md`)
- **Stack**: Rust (lõi DSP + WASM), Dart/Flutter (app), Astro + TypeScript (web), Cloudflare Workers + D1 + Hono
  (máy chủ). Chi tiết và lý do: `docs/ARCHITECTURE.md`.
- **Hạng xác thực**: B - app có kết nối (`AUTH_AND_ACCOUNT.md` mục 1); IdP là tsudev.com (OIDC).
- **Mức phân loại dữ liệu cao nhất**: D2 (tài khoản + dữ liệu đo cá nhân). Không có âm thanh, không vị trí.
- **Người liên hệ khi có sự cố**: chủ dự án tsudev (GitHub `tsudev-tsudev`).

### B.2. Chạy trong 5 phút

Xem `README.md` mục "Chạy trong 5 phút". Tóm tắt:

```bash
cargo test -p sounddb-dsp && (cd packages/dsp-dart && dart test)
(cd apps/app && flutter test)
npx npm@11 install && npm test && npm run build
```

### B.3. Ranh giới sở hữu file

| Vùng | Chủ sở hữu | Ghi chú |
| --- | --- | --- |
| `packages/dsp-core` | agent-sound (DSP) | Đổi thuật toán ⇒ sinh lại `conformance/vectors.json` + sửa `packages/dsp-dart` CÙNG PR |
| `packages/dsp-dart`, `apps/app` | agent-sound (app) | |
| `services/sync-api` | agent-sound (máy chủ) | Migration đã áp dụng là BẤT BIẾN |
| `apps/web` | agent-sound (web) | `public/` icon/favicon là sản phẩm SINH RA |
| `tokens/`, `assets/brand/` | agent-sound | Sinh lại bằng `scripts/build-tokens.mjs`, `apps/web/scripts/brand-assets.mjs` |

### B.4. Điểm lệch chuẩn đã biết

| Lệch ở đâu | Vì sao | Kế hoạch |
| --- | --- | --- |
| Logo: dùng logo tsudev chung | Chưa có logo riêng được chủ dự án duyệt (`BRAND_ASSETS.md` mục 15) | Có logo duyệt ⇒ thay `assets/brand/source/`, sửa `brand.json`, chạy lại dây chuyền |
| iOS chưa đặt `AVAudioSession.Mode.measurement` | Plugin `record` không lộ tham số mode | Thêm kênh nền tảng nhỏ trong `ios/Runner` - `logs/STATE.md` |
| Không ghim chứng chỉ (pinning) | Dữ liệu D2, không phải D3 (`LANGUAGE_SELECTION.md` mục 4) | Xét lại nếu dữ liệu nâng lên D3 |

### B.5. Việc riêng của repo cần biết trước khi sửa

- **Rust là bản tham chiếu.** Mọi con số của app phải khớp bản Rust trên `conformance/vectors.json`
  (`cargo run -p sounddb-dsp --example gen_vectors > conformance/vectors.json`). Bản Dart lệch = lỗi, kể cả khi
  "trông đúng hơn".
- **npm >= 11** (`packageManager`): npm 10 vỡ khi giải peer của vitest 4.1 ("Cannot read properties of null
  (reading 'edgesOut')"). Dùng `npx npm@11 install`.
- **`.gitignore` chuẩn có mẫu `core`** (tệp core dump) - nó chặn im lặng thư mục `apps/app/lib/core/`. Đã mở lại
  bằng `!apps/app/lib/core/`; thêm thư mục tên `core` ở chỗ khác thì phải mở lại tương tự (bài học 17/11: CI đỏ
  vì `format.dart` chưa bao giờ được commit).
- **Cron**: tài khoản Cloudflare đã hết 5 cron Free - đừng thêm `triggers.crons`; việc định kỳ chạy kèm yêu cầu.
- **Tệp chính của Worker chỉ export handler.** Export hằng/hàm thường từ `src/index.ts` làm workerd từ chối khởi
  động ("Incorrect type for map entry"). Đặt chúng ở module khác (`src/maintenance.ts`).
- **CSP trang `/do/` do Worker đặt**, không qua `_headers`: hai luật `_headers` trùng khóa bị NỐI bằng dấu phẩy và
  trình duyệt áp cả hai CSP (WebAssembly bị chặn im lặng).
- **Bộ test máy chủ chạy trên workerd của vitest-pool-workers**, `compatibility_date` của `wrangler.test.jsonc`
  không được mới hơn bản workerd đi kèm.
- Đăng nhập: client OIDC `sounddb` phải được đăng ký trong bảng `OAuthClient` của tsudev với redirect DUY NHẤT
  `https://sounddb.tsudev.com/auth/callback` (phiếu `logs/handover/20261117-01_*`).
