# PHIẾU BÀN GIAO - Kiểm thử toàn diện app trên smartphone thật qua adb (agent-sound)

- **Mã phiếu**: 20261117-06
- **Từ**: agent-sound (phiên 17/11 tối) - **Đến**: phiên agent-sound kế tiếp (+ 👤 chủ dự án ở mục 2)
- **Thời điểm**: 23:10 17/11/2026
- **Trạng thái**: MỞ
- **Mục tiêu**: cài bản mới nhất lên điện thoại Android thật qua adb, tự thao tác TỪNG chức năng, tìm lỗi/lỗ hổng,
  sửa tận gốc kèm test tự động, chuẩn hoá mã, rồi phát hành bản sửa. Không dừng ở "chụp màn hình thấy chạy".

## 0. Đã biết từ phiên trước (đừng làm lại)

- Emulator AVD `sounddb36` (Android 16 x86_64) đã có; APK 26.11.1705 cài + mở được, màn Đo mức đúng, không crash app.
  Máy dev 4 nhân QUÁ TẢI khi chạy emulator cùng các phiên khác (systemui/gms ANR liên tục, màn đen) ⇒ dùng ĐIỆN
  THOẠI THẬT, chỉ dùng emulator khi cần một cỡ màn/phiên bản Android khác và máy đang rảnh.
- Nhóm `kvm` đã cấp nhưng shell của phiên Claude cũ chưa nhận; phiên MỚI sẽ nhận (kiểm `id -Gn`). Nếu chưa: chạy
  qua `wsl.exe -e <script>`.
- `adb shell monkey` treo trên máy chậm ⇒ mở app bằng `am start -n com.tsudev.sounddb/.MainActivity`.
- Mọi lệnh adb bọc `timeout 30` (adb treo im lặng khi thiết bị mất kết nối).
- Manifest: `allowBackup=false`, `usesCleartextTraffic=false`, chỉ MainActivity exported (deep link
  `com.tsudev.sounddb://` cho đăng nhập). Token ở `flutter_secure_storage`, dữ liệu ở sqflite.
- CI: job "Dựng kiểm iOS + macOS" hay bị HUỶ sau 15 phút khi chưa có runner `macos-26` (không phải lỗi mã) ⇒
  `gh run rerun <id> --failed`. Repo KHÔNG bật auto-merge ⇒ chờ check bằng vòng `until` chạy nền rồi `gh pr merge`.

## 1. Kết nối điện thoại từ WSL2 (chọn A; B dự phòng)

Lấy adb: `export PATH=$HOME/Android/Sdk/platform-tools:$PATH`.

**A. Gỡ lỗi không dây (Android 11+, khuyến nghị - không cần driver USB/usbipd):**
1. 👤 Điện thoại: Cài đặt > Giới thiệu > chạm 7 lần "Số hiệu bản dựng" ⇒ Tuỳ chọn nhà phát triển > bật
   **Gỡ lỗi không dây** > "Ghép nối thiết bị bằng mã ghép nối". Điện thoại và PC cùng mạng Wi-Fi.
2. 👤 Gõ trong phiên (mã + cổng ghép nối hiện trên điện thoại, đổi mỗi lần):
   `! ~/Android/Sdk/platform-tools/adb pair <IP>:<CỔNG_GHÉP> <MÃ_6_SỐ>`
3. Agent: `adb connect <IP>:<CỔNG_KẾT_NỐI>` (cổng ở màn Gỡ lỗi không dây, KHÁC cổng ghép) ⇒ `adb devices -l`.
   WSL2 chế độ NAT vẫn kết nối RA mạng LAN được. Không tới được ⇒ dùng `adb.exe` của Windows
   (`/mnt/c/.../platform-tools/adb.exe`) hoặc cách B.

**B. Cáp USB qua usbipd-win:** 👤 PowerShell (admin): `winget install usbipd` ⇒ `usbipd list` ⇒
`usbipd bind --busid <id>` ⇒ `usbipd attach --wsl --busid <id>`; trên điện thoại chấp nhận khoá RSA.

Ghi lại vào phiếu: hãng/model, phiên bản Android, ABI (`getprop ro.product.cpu.abi`), cỡ màn (`wm size`, `wm density`).

## 2. Việc của chủ dự án (👤) cần có trước/trong phiên

1. 👤 Bật gỡ lỗi không dây + chạy lệnh `adb pair` (mục 1A).
2. 👤 Đăng nhập tsudev thật trên app khi agent tới bước đăng nhập (agent không có mật khẩu; KHÔNG gửi mật khẩu cho
   agent). Agent chỉ bấm tới trang đăng nhập, chụp màn hình, rồi chờ.
3. 👤 Cho phép cài từ nguồn ngoài nếu điện thoại hỏi (lần `adb install` đầu tiên trên một số hãng: Xiaomi/Oppo cần bật
   "Cài đặt qua USB").

## 3. Bộ công cụ (dựng một lần, đặt ở `scripts/android/`, commit cùng PR đầu)

- `scripts/android/ui.sh` - hàm tiện ích: `tap_text "<chữ>"` (uiautomator dump ⇒ lấy `bounds` ⇒ `input tap`
  tâm), `shot <tên>` (`exec-out screencap -p` vào `logs/qa/<ngày>/`), `log_app` (`logcat --pid=$(pidof
  com.tsudev.sounddb)`), `wait_text "<chữ>" <giây>`. Bản nháp đã chạy được ở phiên trước:
  ```bash
  d(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null; adb shell cat /sdcard/u.xml; }
  tap_text(){ b=$(d | grep -oE "text=\"$1\"[^>]*bounds=\"\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]\"" | head -1 \
    | grep -oE '\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]'); [ -z "$b" ] && return 1
    read x1 y1 x2 y2 <<<$(echo $b | tr '[],' '   '); adb shell input tap $(((x1+x2)/2)) $(((y1+y2)/2)); }
  ```
  Flutter chỉ lộ chữ cho uiautomator qua Semantics ⇒ nút không có nhãn = LỖI truy cập (ghi vào danh sách lỗi).
- Ảnh chụp/QA KHÔNG commit nếu chứa dữ liệu cá nhân; thư mục `logs/qa/` thêm vào `.gitignore` nếu chưa có.
- Tự động hoá lâu dài: thêm `integration_test` (SDK Flutter) vào `apps/app` + `flutter drive`/`flutter test
  integration_test -d <serial>` cho các luồng chính; quyền micro cấp trước bằng `adb shell pm grant
  com.tsudev.sounddb android.permission.RECORD_AUDIO`. Xét Patrol chỉ khi cần thao tác hộp thoại hệ thống trong
  test (ghi lý do nếu thêm phụ thuộc).

## 4. Kế hoạch theo phase (mỗi phase = một phiên hoặc một PR; cập nhật mục 6 sau MỖI phase)

### Phase 1 - Kết nối + khói (smoke) + mốc cơ sở
- Kết nối (mục 1); `gh release download v26.11.1705 -p '*arm64-setup.apk' -p SHA256SUMS` ⇒ `sha256sum -c` ⇒
  `adb install -r`. Kiểm `dumpsys package com.tsudev.sounddb | grep version`.
- Mốc: thời gian khởi động lạnh (`am start -W` TotalTime), RAM (`dumpsys meminfo com.tsudev.sounddb` PSS), khung
  hình giật (`dumpsys gfxinfo com.tsudev.sounddb reset` ⇒ thao tác 30 s ⇒ đọc Janky frames %).
- Dựng bộ công cụ mục 3.

### Phase 2 - Chức năng, từng tab (đối chiếu kết quả mong đợi, ghi mỗi ca: đạt/lỗi + ảnh + log)
- **Đo mức**: xin quyền lần đầu (cho phép / từ chối / "không hỏi lại" ⇒ app phải hướng dẫn mở Cài đặt, không treo
  nút); Bắt đầu/Dừng; A/C/Z × Nhanh/Chậm/Xung; LAeq, LAFmax/min, LApeak, LAF10/50/90 cập nhật hợp lý; biểu đồ 2 phút;
  giữ màn hình sáng; đang đo mà xoay màn, khoá màn, chuyển app, có cuộc gọi/thông báo ⇒ không crash, không rò micro
  (biểu tượng micro của hệ thống tắt khi dừng); Lưu phiên (`save_session.dart`) với nhãn có dấu tiếng Việt, emoji,
  chuỗi HTML.
- **Kiểm độ chính xác bằng âm chuẩn**: tab Công cụ > Máy phát tạo 1 kHz trên MÁY KHÁC (hoặc loa PC:
  `ffplay -f lavfi "sine=frequency=1000"`), so mức và tần số với bản web (`sounddb.tsudev.com/do/`) đặt cùng chỗ;
  Bộ chỉnh âm đọc 440 Hz khi phát A4. Lệch so với bản Rust tham chiếu ⇒ lỗi (AGENTS.md B.5).
- **Phân tích**: phổ FFT, phổ đồ, 1/1 và 1/3 octave, Thiết lập phổ; nhãn trục không tràn (đã từng tràn 25px).
- **Công cụ**: Bộ chỉnh âm (A4 ±, Giữ đỉnh/Xoá đỉnh), Máy phát (tần số, +50/-50, dừng khi rời tab/ra nền - không phát
  âm sau khi tắt màn hình).
- **Lịch sử**: danh sách, phân trang (`DATA_TABLE.md`), xem chi tiết, xoá, tìm/lọc tiếng Việt có/không dấu
  (`SEARCH_AND_FILTER.md`), dữ liệu rỗng, 1000+ bản ghi (tạo bằng vòng lưu nhanh hoặc chèn sqlite qua
  `run-as com.tsudev.sounddb` - chỉ được nếu bản debug; bản release thì sinh qua UI/integration_test).
- **Cài đặt**: giao diện Sáng/Tối/Hệ thống; hiệu chuẩn (nhập offset, Áp dụng, Khôi phục mặc định ⇒ cảnh báo "Chưa
  hiệu chuẩn" ẩn/hiện đúng); chế độ ngoại tuyến hoàn toàn (không có request mạng nào - kiểm bằng log/`dumpsys
  netstats`); tự đồng bộ; Đồng bộ ngay; Đăng xuất; "Đăng xuất và xoá dữ liệu cục bộ" (dữ liệu thật sự mất).
- **Đăng nhập + đồng bộ** (👤 mục 2.2): luồng app_links `com.tsudev.sounddb://` về app; huỷ giữa chừng; lưu trên điện
  thoại ⇒ thấy trên web và ngược lại; sửa cùng bản ghi ở hai nơi (ghi sau thắng, ADR-0004); mất mạng khi đồng bộ
  (`adb shell cmd connectivity airplane-mode enable`) ⇒ thử lại khi có mạng, không nhân đôi bản ghi.

### Phase 3 - Phi chức năng + bảo mật
- Khả năng truy cập (`ACCESSIBILITY.md`): TalkBack đọc được mọi nút; `settings put system font_scale 2.0` không tràn
  chữ; vùng chạm ≥ 48dp; tương phản.
- Cỡ màn: `wm size 720x1280` + `wm density 320`, máy gập/chia đôi màn hình; nhớ `wm size reset; wm density reset`.
- Chết tiến trình: đưa app ra nền ⇒ `adb shell am kill com.tsudev.sounddb` ⇒ mở lại: không mất phiên đang lưu dở,
  không crash.
- Đo lâu 30 phút: RAM không tăng mãi, pin/nhiệt (`dumpsys batterystats --reset` trước, đọc sau).
- Bảo mật (`SECURITY_BASELINE.md`): logcat không in token/cookie/mã OIDC (`logcat | grep -iE "token|code=|bearer"`);
  deep link giả `adb shell am start -d "com.tsudev.sounddb://auth?code=x&state=sai"` bị từ chối (kiểm `state`/PKCE);
  `adb backup` bị chặn; không có thư mục/tệp đọc được bởi app khác; HTTPS-only; đăng xuất xoá token khỏi secure
  storage; không ghi âm thanh xuống đĩa (D2: "âm thanh không bao giờ rời thiết bị" - kiểm thư mục dữ liệu app).
- Quyền: `pm revoke ... RECORD_AUDIO` khi đang đo ⇒ app xử lý êm.

### Phase 4 - Sửa lỗi + chuẩn hoá mã
- Mỗi lỗi: tái hiện ⇒ viết test (unit/widget/integration) đỏ ⇒ sửa ⇒ xanh. Đổi DSP ⇒ sửa Rust trước, sinh lại
  `conformance/vectors.json`, sửa Dart CÙNG PR.
- Gộp PR theo vùng (đo/phân tích/lịch sử/cài đặt/đồng bộ), không một PR khổng lồ. Cổng tại máy trước khi đẩy:
  `cargo test -p sounddb-dsp && (cd packages/dsp-dart && dart test) && (cd apps/app && flutter analyze && flutter test)`.
- Chuẩn hoá: `flutter analyze` 0 cảnh báo; tách widget quá dài (>300 dòng) theo feature; trạng thái/đồng bộ qua
  `AppScope` thống nhất; chuỗi giao diện gom một chỗ nếu đang rải rác; token giao diện chỉ lấy từ
  `theme/tokens.g.dart` (không màu cứng). Mọi đổi kiến trúc lớn ⇒ ADR mới trong `docs/adr/`.

### Phase 5 - Phát hành bản sửa
- Bản `26.11.DDNN` mới (đừng dùng `v26.11.1703`). Nếu `tsudev-standards` v3.7.0 đã ra: làm luôn kế hoạch đổi tên
  tệp phiếu V1 mục 6 (phát hành cả tên cũ lẫn mới). Dựng thử APK ký số ở máy VỚI `key.properties` trước khi tag
  (phiếu 05 mục 4). Cài bản mới lên điện thoại đè bản cũ (kiểm nâng cấp giữ dữ liệu), chạy lại smoke.

## 5. Tiêu chí hoàn thành

- Mọi ca ở Phase 2-3 có kết quả đạt/lỗi kèm bằng chứng; mọi lỗi mức Cao/Nghiêm trọng đã sửa + có test; lỗi còn lại
  có lý do và kế hoạch.
- Không crash/ANR của app trong logcat suốt đợt thử; jank < 5% khung hình ở màn Đo mức và Phân tích.
- Bản phát hành mới cài đè được, dữ liệu cũ còn nguyên; CI xanh; STATE + phiếu cập nhật.

## 6. Kết quả (phiên kế tiếp điền theo từng phase)

| Phase | Trạng thái | PR | Ghi chú |
| --- | --- | --- | --- |
| 1 | xong (23/11) | #38 | Samsung SM-M325FV, Android 13, USB qua `adb.exe` Windows + Wi-Fi `adb tcpip 5555` cho adb/flutter của WSL. **Khởi động lạnh** (`am start -W`, 26.11.2301): 2137 ms lần đầu sau cài, rồi 856 / 681 ms; bản sửa: 950-1206 ms. **RAM** PSS: 96,8 MB đứng yên → 108-122 MB khi đo (Đo mức/Phân tích). **Nhịp vẽ khi đo** (log SurfaceFlinger, bản release): 26.11.2301 vẽ 78-81 khung/giây dù dữ liệu chỉ đổi 20 lần/giây ⇒ QA-04; bản sửa 19-20 khung/giây, đứng yên 0 khung. **Jank** (FrameTiming, `integration_test/perf_test.dart`, bản profile, 90 Hz): trước sửa build p90 25-33 ms / p99 60-68 ms (DSP chạy trong khung), sau sửa build p99 2,7-3,3 ms; raster p50 ~9,5 ms là chi phí nền của máy (Mali-G52, 1080×2400) - tỉ lệ "giật" của bộ đo KHÔNG dùng làm tiêu chí vì binding integration_test tự xin khung (~80/giây), xem LES-20261123-2011-102b trong AKB |
| 2 | xong một phần (23/11) | #30, #31, #38 | **Nâng cấp 26.11.1705 → 26.11.2301** (`sha256sum -c SHA256SUMS.txt` + `gh attestation verify` đạt, `install -r`): Lịch sử từ 0/0 (QA-01) lên 2/2, dữ liệu 21/11 còn nguyên, nhãn `<b>QA 01</b>&"x` hiện dạng chữ (ảnh `p5-truoc/sau-nang-cap-lich-su.png`). **Âm chuẩn 1 kHz** (PC phát `[console]::beep(1000)`): app LAF 64,6 dB(A), Phân tích "Tần số trội 1000,0 Hz", mức đỉnh 64,6 dB - khớp; web `/do/` trên Chrome cùng máy, cùng chỗ: 84,3 dB(A), nền 62,3 (app nền ~41) ⇒ QA-06. **1200 bản ghi** (`integration_test/history_scale_test.dart`, gói `.profile`): đếm 2 ms, 100 dòng đầu/cuối 23/26 ms, mở tab tới "1-10 / 1200" 113 ms, sắp mới nhất trước đúng - ĐẠT. Tạm dừng/Tiếp tục ⇒ QA-03. CHƯA (23/11): đăng nhập + đồng bộ (👤). **24/11** (bản profile `.profile`, cài song song): **Bộ chỉnh âm** - Chrome trên cùng máy phát sin 440 Hz (WebAudio qua CDP) ⇒ 440,0 Hz, MIDI 69, lệch -0,0 cent, độ rõ 100 % - ĐẠT (`p2-bo-chinh-am-440-chrome.png`). **Máy phát** 440 Hz phát được; ra nền ⇒ QA-09. **Cài đặt**: giao diện Tối đúng (`p2-cai-dat-toi-ngoai-tuyen-tat.png`); ngoại tuyến bật ⇒ bấm Đăng nhập không mở trình duyệt, báo "Đang bật Chế độ ngoại tuyến..." - ĐẠT; hiệu chuẩn nhập tay 250 ⇒ "Offset phải là số trong 0-200 dB", 110 ⇒ "Đã hiệu chuẩn · offset 110,00 dB" + banner Đo mức biến mất, Khôi phục mặc định về 120 - ĐẠT. **Tìm/lọc Lịch sử** (tính năng mới PR #41): `phien`/`tet`(→ "tét")/`duong giai` không dấu ĐẠT, rỗng kèm từ khoá ĐẠT, 7 ngày/1 năm/tuỳ chọn 20-24/11 ĐẠT; Lịch sử sau lưu ⇒ QA-07 |
| 3 | bắt đầu (21/11, 23/11) | #38 | Deep link giả ⇒ không đăng nhập (ĐẠT, 21/11). 23/11: `allowBackup` tắt (cờ gói không có ALLOW_BACKUP) - ĐẠT; logcat không có token/bearer/cookie của app - ĐẠT; app bị `am kill` khi ở nền ⇒ mở lại bình thường - ĐẠT; `pm revoke RECORD_AUDIO` khi đang đo ⇒ Android giết tiến trình (hành vi hệ thống), log crash không có app - ĐẠT; mở lại + bấm đo ⇒ quyền về `granted`, đo được nhưng KHÔNG chụp được hộp thoại (uiautomator lỗi khi đang đo) - cần xem bằng mắt. Trợ năng ⇒ QA-05. **24/11:** `font_scale 2.0` ⇒ QA-08; `wm size 720x1280` + density 320 (360×640 dp) mọi tab không tràn, logcat không `overflow` - ĐẠT; quyền "không hỏi lại" ⇒ không crash, QA-10 (thiếu nút mở cài đặt); **Đo 30 phút** (bản profile, Đo mức, `logs/qa/20261124/p3-do-30-phut.tsv`): PSS 177 → 187 MB trong 3 phút đầu rồi phẳng 186-187,5 MB tới phút 24 - KHÔNG rò bộ nhớ; CPU ⇒ QA-11; phút 25 dữ liệu dừng vì cáp USB rớt + tác vụ bị đóng từ màn Gần đây (`am_kill ... remove task` 07:24:26, adj 900 - không phải crash). TalkBack (Samsung) bật được, tiêu điểm đầu vào tiêu đề "Đo mức âm" - nhưng cử chỉ `adb input swipe` không được TalkBack nhận và agent không nghe được ⇒ 👤 nghe thử thật (bật TalkBack, vuốt qua Đo mức khi đang đo: chỉ đọc vùng mức khi đổi, không đọc dồn); đã tắt lại (`enabled_accessibility_services` null, `accessibility_enabled 0`). |
| 4 | QA-01..05, QA-07..10 (24/11) | #30, #31, #38, #41 | QA-11 (CPU ~0,9 lõi khi đo) MỞ - cần đổi DSP (Rust + vector + Dart) |
| 5 | 26.11.2301 cài thử ĐẠT; **26.11.2302 phát hành** (23/11) | #36, #39 | `v26.11.2302` Latest (QA-03/04/05), run 45212957432 mọi job đạt (gồm VirusTotal); `sha256sum -c SHA256SUMS.txt` + `gh attestation verify` APK arm64 đạt. Cùng mã đã dựng release ký số tại máy và cài đè trên SM-M325FV (versionCode 26114303, dữ liệu giữ nguyên, 19-20 khung/giây khi đo). APK chính thức versionCode 26114302 THẤP hơn bản thử ⇒ chưa cài đè được (Android từ chối hạ cấp); adb.exe Windows còn "unauthorized" sau `adb usb` dù đã bấm Cho phép - bản chính thức kế tiếp sẽ cài đè bình thường |

Danh sách lỗi (mã `QA-nn`, mức, tab, cách tái hiện, trạng thái):

- **QA-01 - Nghiêm trọng - Lịch sử**: SQLite hệ thống của Samsung SM-M325FV (Android 13) không có `json_extract` ⇒
  `listSessions` ném "no such function: json_extract", Lịch sử trống dù báo "Đã lưu". Test dùng SQLite ffi (có JSON1)
  nên không thấy. Sửa: DB v2 cột `sessions.started_at` + chỉ mục, nâng cấp v1 điền lại bằng Dart; Lịch sử báo
  `historyLoadFailed` thay vì trống im lặng; test cấm hàm JSON1 trong SQL của `lib/`. **ĐÃ SỬA** PR #30, phát hành 26.11.2301.
- **QA-02 - Trung bình - Phân tích > Dải octave**: vòng 1/3 octave chạy tâm 1 Hz..20 kHz, tâm < 10 Hz làm tròn danh
  định thành 10 ⇒ nhãn trục "10 10 10 10 16..." + cảnh báo "Dải thấp nhất chỉ phủ 0,0 bin FFT". Sửa Rust tham chiếu +
  Dart (x = -20..13), `vectors.json` không đổi. **ĐÃ SỬA** PR #31, phát hành 26.11.2301.

- **QA-03 - Cao - Đo mức**: bấm "Tiếp tục" sau "Tạm dừng" xoá sạch phiên (đồ thị 2 phút, LAeq/Max/Min, mốc bắt đầu) -
  `start()` gán `state = starting` TRƯỚC khi kiểm "đang tạm dừng". Máy thật: ảnh `p2-qa03-tam-dung.png` (~1 phút dữ
  liệu) → `p2-qa03-sau-tiep-tuc.png` (chỉ đoạn mới). Test `measurement_resume_test.dart` đỏ → xanh. **ĐÃ SỬA** PR #38.
- **QA-04 - Trung bình - Đo mức/Phân tích (hiệu năng, pin)**: nhịp hiển thị là `Ticker` ⇒ xin khung ở MỌI vsync (90 Hz)
  dù `_onTick` bỏ qua khung cách < 50 ms ⇒ 78-81 khung/giây raster lại toàn màn; FFT 8192 + cao độ + dải octave chạy
  TRONG khung (build p90 25-33 ms). Sửa: `Timer.periodic(50 ms)` ⇒ 19-20 khung/giây, build p99 ~3 ms. Test "không
  giữ callback theo từng khung" đỏ → xanh. **ĐÃ SỬA** PR #38.
- **QA-05 - Trung bình - Trợ năng**: số đo bọc `Semantics(liveRegion: true)` với nhãn đổi mỗi 50 ms ⇒ 115-117 sự kiện
  trợ năng / ~5 s khi đo (2 khi tạm dừng) - TalkBack đọc dồn liên tục. Sửa: vùng live chỉ mang tên vùng mức (an toàn /
  cần lưu ý / nguy hại - vi + en), số đo là nút con thường. Máy thật sau sửa: 66 sự kiện / ~5 s (cập nhật không live,
  TalkBack không đọc), cây có "Mức an toàn" + "Mức âm LAF 48,9 đề-xi-ben". Test `meter_semantics_test.dart` đỏ →
  xanh. **ĐÃ SỬA** PR #38. Còn: kiểm bằng TalkBack thật.
- **QA-06 - Trung bình - Web vs app (chưa hiệu chuẩn)**: cùng điện thoại, cùng tông 1 kHz: app 64,6 dB(A) (−55,4 dBFS,
  offset 120, nguồn `unprocessed`), web Chrome 84,3 dB(A) (−15,7 dBFS, offset mặc định 100). Chuỗi thu chênh ~40 dB
  thô; nền 41 vs 62 dB(A) ⇒ lệch cố định ~+20 dB. Lõi DSP không lệch (cùng 1000,0 Hz; Dart khớp vector Rust). Chưa có
  máy đo chuẩn ⇒ chưa biết bên nào đúng tuyệt đối. **MỞ** - bước kế: in `track.getSettings()` trên Chrome Android
  (autoGainControl có thật sự tắt?), so nguồn `mic` vs `unprocessed` trên app; cân nhắc offset mặc định theo nền tảng
  (ghi ADR nếu đổi). Ảnh `p2-1khz-app-*.png`, `p2-1khz-web-chrome.png`, `p2-nen-web-chrome.png`.
  **24/11 (sound-db-c9):** Chrome 158 Android `getSettings()` với ràng buộc `may-do.ts`: AGC/AEC/NS đều `false`, 48 kHz
  ⇒ AGC KHÔNG phải nguyên nhân. Nền thô -33..-36 dBFS (bật xử lý mặc định: -102). Chuỗi thu Chrome nhạy hơn
  `unprocessed` ~40 dB. CDD 5.4 (SHOULD): `VOICE_RECOGNITION` 90 dB SPL 1 kHz ⇒ -22,4 dBFS ⇒ offset ~112,4. Socket
  `chrome_devtools_remote` là của Edge; Chrome ở `chrome_devtools_remote_<pid>`. Bước kế: chạy
  `integration_test/mic_source_test.dart` (unprocessed/mic/voiceRecognition, tông 1 kHz) - lần 24/11 hỏng
  `AudioRecord initialization check failed -1` (đóng tab Chrome `/do/`, force-stop app rồi chạy lại), có số ⇒ ADR + test.
  **Kết luận 24/11 (sau):** lỗi `-1` là do `flutter drive` cài lại gói ⇒ mất quyền micro (test giờ tự xin quyền).
  `dumpsys audio`: Chrome tắt xử lý ⇒ nguồn **`src:MIC`**; bật xử lý ⇒ `VOICE_COMMUNICATION`. Bộ đo nguồn thu (nền
  phòng, 3 vòng xen kẽ, cùng lúc): `unprocessed` -75,2..-76,0 dBFS, `voiceRecognition` -52,3..-53,3, `mic` -23,3..-32,5
  (dao động 9 dB giữa các vòng ⇒ có xử lý của hãng dù đã tắt AGC). Tông 1 kHz từ loa PC không tới máy lần này (mức tại
  1 kHz ~-118 dBFS mọi nguồn) ⇒ so bằng nền rộng dải. **ĐÓNG - không đổi mã:** độ lệch web/app là do đường thu `MIC`
  của Chrome trên Samsung nhạy hơn `UNPROCESSED` ~45-50 dB (offset 100 vs 120 bù được một phần). Bằng chứng chỉ một
  máy, không có máy đo chuẩn, `MIC` lại dao động ⇒ KHÔNG đổi offset mặc định web (một con số cho mọi trình duyệt/hãng
  sẽ sai ở máy khác); cả web lẫn app đã nói rõ "chưa hiệu chuẩn" và dẫn tới hiệu chuẩn. Xét lại khi có máy đo chuẩn
  hoặc số đo ≥ 3 máy (khi đó ghi ADR). App giữ `unprocessed` (ít xử lý nhất, ổn định giữa các vòng).
- **QA-07 - Trung bình - Lịch sử**: lưu phiên ở Đo mức rồi mở Lịch sử ⇒ vẫn "Chưa có phiên đo nào", 0-0 / 0 dù vừa
  báo "Đã lưu"; phải bấm Tải lại. Tab nằm trong `IndexedStack`, chỉ tải một lần + chỉ nghe đồng bộ. Sửa: `LocalStore.changes`
  (`ValueNotifier`, tăng ở mọi lần ghi/xoá sạch), Lịch sử nghe nó. Test `history_refresh_test.dart` đỏ → xanh; máy
  thật: phiên 06:41 hiện ngay 1-3 / 3 (ảnh `logs/qa/20261124/p4-qa07-sau-sua.png`). **ĐÃ SỬA** PR #41.
- **QA-08 - Cao (trợ năng) - Lịch sử**: `font_scale 2.0` + bàn phím mở khi gõ tìm ⇒ thanh tìm/lọc cố định chiếm hết
  thẻ, danh sách còn 0 px - kết quả không hiện, không cuộn tới được; chip khoảng tuỳ chọn bị cắt; chân bảng tràn 199 px.
  Sửa: thanh lọc cuộn cùng danh sách (`CustomScrollView`), `PaginationFooter` gọn theo tỉ lệ chữ + bỏ chiều cao cứng,
  chip bỏ năm khi cùng năm, nhãn 2 dòng. Test `history_large_text_test.dart` đỏ → xanh (kiểm cả khi bỏ bản sửa); máy
  thật ảnh `p3-font2-lich-su.png` (trước) → `p4-qa08-font2-ban-phim.png` (sau). **ĐÃ SỬA** PR #41.
- **QA-09 - Trung bình - Công cụ > Phát tín hiệu**: đang phát 440 Hz, ra màn hình chính rồi quay lại ⇒ trình phát
  `paused`/`idle` (không tiếng) nhưng nút vẫn "Dừng phát". Sửa: `WidgetsBindingObserver` dừng hẳn khi `paused`/`hidden`
  (an toàn thính giác) + nút theo `onPlayerStateChanged`; chặn `setState` sau `dispose` khi phát lỗi. Test
  `generator_lifecycle_test.dart` đỏ → xanh. **ĐÃ SỬA** PR #41.
- **QA-10 - Thấp - Đo mức (quyền "không hỏi lại")**: `pm revoke` + cờ `user-fixed` ⇒ bấm Bắt đầu đo hiện banner lỗi
  "cần quyền dùng micro... cấp quyền trong cài đặt hệ thống", không crash (ĐẠT) nhưng KHÔNG có nút mở thẳng trang quyền
  của app. Sửa: `AudioInputException.code` + `MeasurementController.errorCode`, banner có nút "Mở cài đặt" (chỉ Android)
  gọi kênh `com.tsudev.sounddb/system` → `ACTION_APPLICATION_DETAILS_SETTINGS` (`MainActivity.kt`). Test
  `mic_permission_settings_test.dart` đỏ → xanh; máy thật: nút mở `com.android.settings/.applications.InstalledAppDetails`
  của Sound Db (ảnh `p4-qa10-nut-mo-cai-dat.png`). **ĐÃ SỬA** PR #41. iOS chưa có nút (cần phiên macOS, AGENTS B.4).
- **QA-11 - Trung bình - Đo mức (pin/CPU)**: khi đo, tiến trình dùng ~0,84-0,93 lõi CPU liên tục (CLK_TCK 100: 84 jiffies/s
  ở tab Cài đặt - đồng hồ ẩn, 92 ở Đo mức, 93 ở Phân tích; đứng yên 0). Theo luồng: luồng chính (Dart, luồng UI gộp
  platform) ~65 %, `1.raster` ~13 %, thu âm ~3 % ⇒ chi phí là DSP Dart chạy trên luồng chính, không phải vẽ. Đo 24 phút
  liên tục: pin 80 → 76 % dù đang sạc USB, nhiệt độ pin 38,4 → 39,5 °C. **MỞ** - hướng sửa: đo hồ sơ CPU (DevTools
  CPU profiler, bản profile) xem khâu nào (lọc trọng số A/C/Z, dàn lọc 1/3 octave ở 48 kHz, FFT); dàn 1/3 octave
  nhiều tầng hạ mẫu (IEC 61260-1 cho phép) và/hoặc chuyển DSP sang isolate riêng. Đổi thuật toán ⇒ Rust tham chiếu +
  `conformance/vectors.json` + Dart CÙNG PR (AGENTS B.3). Bộ đo: `/proc/<pid>/stat` cột 14+15 trong 20 s.
  **24/11 tối (sound-db-56) - SỬA PHẦN LỚN, chờ đo máy thật.** Hồ sơ CPU bằng `packages/dsp-dart/tool/bench.dart` (AOT, mô
  phỏng 48 kHz + 20 nhịp/giây như app): `bandLevels` 51 % (78 dải × quét đủ 4097 bin + `pow`/`log` từng bin mỗi nhịp),
  dò cao độ 22 % (chạy ở MỌI tab), FFT 12 %, `spectrumDb` 11 %, lọc A/C/Z mỗi mẫu chỉ 3 %. Sửa KHÔNG đổi thuật toán:
  (1) `SpectrumAnalyzer` lập sẵn bảng (bin, độ phủ) mỗi dải + bảng hệ số trọng số theo bin, giữ đúng biểu thức và thứ
  tự cộng ⇒ so 126 762 giá trị với công thức cũ: 0 khác bit, `vectors.json` không đổi, Rust không cần sửa; (2) chỉ dò
  cao độ khi tab Bộ chỉnh âm hiển thị (`demandPitch` + `TickerMode`; trang ẩn của `IndexedStack` KHÔNG tự tắt
  TickerMode ở Flutter 3.47 ⇒ vỏ app bọc `TickerMode(enabled: i == _index)`). Test `pitch_demand_test.dart` đỏ ⇒ xanh.
  Số đo x86 (3 lượt xen kẽ, máy có tải): 105-129k ⇒ 22-35k µs CPU mỗi giây âm (giảm ~75 %) ở tab thường, ~50 % ở Bộ
  chỉnh âm. CÒN: đo `cpu_rate` trên SM-M325FV (mục tiêu < 0,3 lõi ở Đo mức); nếu chưa đạt ⇒ FFT thực (đóng gói N/2
  phức) cho phổ + NSDF, khâu lớn nhất còn lại (cần Rust + vector cùng PR).

Đo trên máy 21/11 (bằng chứng ảnh): FFT 8192 Hann 5,86 Hz/bin trọng số A hiển thị đúng, nhãn trục không tràn; Cài
đặt hiện phiên bản 26.11.1705 và khối "Âm thanh không bao giờ rời thiết bị".

## 7. Prompt khởi động chuẩn cho phiên kế tiếp (chủ dự án dán nguyên văn)

```text
Bạn là agent-sound, repo ~/projects/sound-db. Thực hiện theo đúng thứ tự, không bỏ bước:

1. KHỞI ĐỘNG: đọc CLAUDE.md, AGENTS.md, .standards/AGENTS.md (+ docs/AGENT_PROTOCOL.md), logs/STATE.md,
   logs/LOCKS.md, rồi phiếu logs/handover/20261117-06_ke-hoach-kiem-thu-smartphone-adb.md (việc CHÍNH) và
   20261117-V1_*.md mục 6. `git status`, `git log --oneline -5`, `gh pr list` (PR còn mở của phiên trước ⇒ chờ CI
   xanh rồi merge trước khi làm việc mới). Kiểm nhanh: `id -Gn` có kvm; `gh release list -R
   tsudev-org/tsudev-standards -L1` (v3.7.0 đã ra chưa); `curl -s -o /dev/null -w '%{http_code}'
   https://tsudev.com/oidc/interaction/x` (phải 307).
2. GHI KHOÁ + "Đang thực hiện" trong STATE trước khi sửa file; xoá khoá ngay khi xong.
3. LÀM phiếu 06 theo phase 1→5. Bắt đầu Phase 1: nếu `adb devices` trống thì dừng và yêu cầu tôi bật Gỡ lỗi không
   dây + chạy `! ~/Android/Sdk/platform-tools/adb pair <IP>:<cổng> <mã>` (đưa đúng câu lệnh). KHÔNG dùng emulator
   khi máy đang chạy phiên khác (đã quá tải).
4. NGUYÊN TẮC: mọi kết luận phải có bằng chứng (ảnh/log/số đo); mỗi lỗi ⇒ mã QA-nn trong phiếu 06 mục 6 ⇒ test tái
   hiện đỏ ⇒ sửa tận gốc ⇒ xanh; Rust là bản tham chiếu DSP; không sửa .standards/; không tạo/đổi tên repo theo
   tên cũ (~/.claude/CLAUDE.md); không hỏi lại điều đã rõ trong phiếu; mật khẩu/đăng nhập tsudev là việc của tôi.
5. TIẾT KIỆM: chạy cổng tại máy đúng phần bị sửa trước khi đẩy; gộp PR theo vùng; chờ CI bằng vòng `until` chạy
   nền (repo không có auto-merge); job iOS bị huỷ khi chờ runner ⇒ `gh run rerun <id> --failed`; bọc lệnh adb trong
   `timeout 30`; không đọc lại file vừa ghi.
6. KẾT THÚC MỖI PHASE: cập nhật phiếu 06 mục 6 + STATE (Đã hoàn thành, hàng đợi), PR + merge. Hết phiên/sắp
   đầy ngữ cảnh: viết phiếu bàn giao mới `logs/handover/<YYYYMMDD>-NN_*.md` (việc dang dở + bước tiếp theo CỤ THỂ +
   prompt khởi động cho phiên sau theo khuôn này), main sạch, LOCKS trống, không tiến trình nền (emulator/adb).
```
