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
| 1 | chưa làm | | |
| 2 | chưa làm | | |
| 3 | chưa làm | | |
| 4 | chưa làm | | |
| 5 | chưa làm | | |

Danh sách lỗi (mã `QA-nn`, mức, tab, cách tái hiện, trạng thái):

-

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
