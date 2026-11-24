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
| Logo riêng (20/11/2026, phiếu LG1) cắt vuông 704 px từ ảnh gốc 1024 (`brand.json` `crop`) ⇒ icon 1024 là phóng to | Ảnh gốc có dấu ✦ của công cụ tạo ảnh ở góc phải dưới; không sửa pixel tệp gốc (`BRAND_ASSETS.md` mục 15) | Có bản gốc sạch ≥ 1024 quanh logo ⇒ thay `assets/brand/source/logo-sound-db.png`, bỏ `crop`, chạy lại dây chuyền |
| Bản ghi đồng bộ (chỉ người dùng TsuDEV Pro) chưa mã hoá đầu cuối (PRODUCT_POLICY 7.1 N3) | Bảng điều khiển web đọc dữ liệu ở máy chủ (ADR-0005 mục 3) | Chuyển sang TsuDEV Sync (`tsusync`) khi thư viện Dart ổn định |
| Lời xin quyền micro iOS/macOS (`NSMicrophoneUsageDescription`) chỉ tiếng Việt; app/web đã vi + en (20/11/2026) | Bản dịch `InfoPlist.strings` cần thêm nhóm biến thể vào dự án Xcode, không làm được trên máy dev Linux | Thêm `en.lproj/InfoPlist.strings` khi có phiên trên macOS (cùng đợt nộp App Store) |
| Tìm/lọc Lịch sử (24/11/2026, app + web) xếp theo thời gian, không theo điểm liên quan (`SEARCH_AND_FILTER.md` mục 5); không facet, không tìm gần đúng; API giữ `items/total` + thêm `meta.query_normalized` | Lịch sử là dữ liệu đo của chính người dùng, vài nghìn dòng; người dùng nhớ phiên theo thời điểm. Khớp = mọi từ (đã bỏ dấu) nằm trong `search_norm` (tính lúc ghi) | Xét lại khi có yêu cầu thật hoặc số phiên một người > 10.000 |
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
- **`wrangler dev` đổi header `Origin`** thành tên miền của route (`http://sound.tsudev.com`, `http://sounddb.tsudev.com`) ⇒ mọi lệnh ghi từ
  trình duyệt bị chặn CSRF ở local. Chạy `wrangler dev --local-upstream localhost:8787` và đặt
  `PUBLIC_ORIGIN=http://localhost:8787` trong `.dev.vars`.
- **Cron**: tài khoản Cloudflare đã hết 5 cron Free - đừng thêm `triggers.crons`; việc định kỳ chạy kèm yêu cầu.
- **i18n** (PRODUCT_POLICY mục 1): app - chuỗi ở `apps/app/lib/l10n/app_{vi,en}.arb` (bản gốc vi, `flutter gen-l10n`
  sinh `app_localizations*.dart` - commit kèm); trong widget dùng `context.l10n`, ngoài cây widget dùng `l10nNow`;
  số/ngày qua `core/format.dart` (theo ngôn ngữ đang hiển thị). Web - chuỗi ở `apps/web/src/i18n/{vi,en}.ts`, tiếng
  Anh ở `/en/` cùng đường dẫn con; `public/lang.js` tự chọn theo trình duyệt ở lần vào đầu. Trang mới ⇒ thêm view ở
  `src/views/` + hai lớp bọc `src/pages/x.astro`, `src/pages/en/x.astro`. Trang cần header riêng của Worker (như
  `/do/`) phải thêm cả bản `/en/` vào `run_worker_first`.
- **Tệp chính của Worker chỉ export handler.** Export hằng/hàm thường từ `src/index.ts` làm workerd từ chối khởi
  động ("Incorrect type for map entry"). Đặt chúng ở module khác (`src/maintenance.ts`).
- **CSP trang `/do/` do Worker đặt**, không qua `_headers`: hai luật `_headers` trùng khóa bị NỐI bằng dấu phẩy và
  trình duyệt áp cả hai CSP (WebAssembly bị chặn im lặng).
- **Bộ test máy chủ chạy trên workerd của vitest-pool-workers**, `compatibility_date` của `wrangler.test.jsonc`
  không được mới hơn bản workerd đi kèm.
- **TsuDEV Pro** (ADR-0005): đẩy dữ liệu = Pro, máy chủ kiểm qua kênh RP tsudev bằng secret `RP_PRIVATE_JWK` (khoá
  ở `~/.config/tsudev/sounddb/`); JWK công khai phải nằm ở `OAuthClient.rpPublicJwk` của client `sounddb` trên tsudev.
  Xoá dữ liệu đám mây vì hết Pro CHỈ qua `src/pro/purge.ts` (hỏi kênh trạng thái trước khi xoá).
- **Kiểm thử máy thật** (phiếu 06): `scripts/android/ui.sh` (adb.exe Windows). Bản profile có hậu tố `.profile`
  (`build.gradle.kts`) - đừng bỏ: profile ký khoá debug, cài đè bản release thì `flutter drive` GỠ app và mất dữ liệu
  thật. Hiệu năng: `integration_test/perf_test.dart`; quy mô Lịch sử: `integration_test/history_scale_test.dart`. Đo
  nhịp vẽ bản release bằng log `queueBuffer: fps` (Samsung) - `gfxinfo` không đếm khung Flutter. Đừng chạy lệnh
  `flutter` khác khi gradle đang dựng release: nó sinh lại `GeneratedPluginRegistrant` kèm `integration_test` ⇒
  "package dev.flutter.plugins.integration_test does not exist". Dựng release thử tại máy để cài đè: `--build-number`
  = ĐÚNG versionCode bản sắp phát hành (CI `--split-per-abi`: số dựng pubspec + mã ABI × 1000, arm64 = 2 ⇒ 26112302
  + 2000 = 26114302), KHÔNG cao hơn - nếu không bản
  chính thức sẽ bị Android từ chối như hạ cấp (23/11: bản thử 26114303 chặn 26.11.2302).
- **Bẫy máy thật đã gặp (24/11, chi tiết AKB `LES-20261124-1053-*`)**:
  - KHÔNG chạy `adb usb` (23/11: máy về "unauthorized", phải thu hồi uỷ quyền + cắm lại). adb của WSL qua Wi-Fi
    (`adb.exe tcpip 5555` rồi `adb connect <ip>:5555`) dùng khoá RSA RIÊNG ⇒ máy hỏi cho phép lần nữa, tích "Luôn cho
    phép". Không trỏ adb WSL sang khoá của Windows (bị chặn quyền).
  - `flutter drive` cài lại gói ⇒ quyền `pm grant` trước đó MẤT (`AudioRecord ... check failed -1`) - test tự xin quyền,
    tap "Trong khi dùng ứng dụng" bằng script nền.
  - Đang đo ⇒ `uiautomator dump` hỏng (màn vẽ liên tục): bấm theo toạ độ (nút Tạm dừng 875,157 ở 1080×2400), dừng đo rồi
    mới dump. Bấm đúng nhãn: `tapx` (khớp chính xác, hiểu `&amp;`) thay `tap_text` (chuỗi con).
  - Chrome DevTools trên máy: `@chrome_devtools_remote` (không hậu tố) là của **Edge**; Chrome ở
    `chrome_devtools_remote_$(pidof com.android.chrome)`. `adb.exe forward` chỉ mở localhost Windows ⇒ client CDP chạy
    bằng `node.exe`. Không in danh sách tab (`/json`) - lộ tab cá nhân. Loa PC (`[console]::beep`) có lúc không phát ⇒
    nguồn tông chuẩn: WebAudio trong Chrome trên chính máy (CDP) - Bộ chỉnh âm đọc 440,0 Hz.
  - TalkBack bật bằng `settings put secure enabled_accessibility_services ...TalkBackService` mở trang hướng dẫn lần đầu;
    cử chỉ `input swipe` KHÔNG được TalkBack nhận ⇒ nghe thử thật là việc 👤. Ghi lại giá trị cũ, tắt ngay sau khi thử.
  - CPU: `cpu_rate` trong `ui.sh` (jiffies/giây từ `/proc/<pid>/stat`, 100 = một lõi). Đo dài: cáp USB có thể rớt và
    người dùng có thể đóng app từ Gần đây (`am_kill ... remove task` - không phải crash) ⇒ ghi log theo phút.
  - Chỉ `dart format` tệp mình sửa (`dart format lib` định dạng lại ~27 tệp, gồm tệp l10n sinh ra).
- Đăng nhập: client OIDC `sounddb` phải được đăng ký trong bảng `OAuthClient` của tsudev với ĐÚNG hai redirect:
  `https://sound.tsudev.com/auth/callback` + tên cũ `https://sounddb.tsudev.com/auth/callback` (giữ vĩnh viễn, ADR-0007;
  phiếu `logs/handover/20261117-01_*`, tsudev SDB2).
