#!/usr/bin/env bash
# Tiện ích kiểm thử app Sound Db trên điện thoại thật qua adb (phiếu logs/handover/20261117-06 mục 3).
# Dùng: `source scripts/android/ui.sh` rồi gọi `tap_text "Bắt đầu"`, `shot do-muc`, `wait_text "Lịch sử" 10`...
#
# WSL2 không thấy thiết bị USB ⇒ mặc định dùng adb.exe của Windows nếu có (đặt ADB=... để đổi).
# Mọi lệnh adb bọc `timeout` (adb treo im lặng khi mất kết nối).

PKG=com.tsudev.sounddb
if [ -z "${ADB:-}" ]; then
  for c in /mnt/c/Users/*/AppData/Local/Android/Sdk/platform-tools/adb.exe "$HOME/Android/Sdk/platform-tools/adb"; do
    [ -x "$c" ] && { ADB=$c; break; }
  done
fi
QA_DIR=${QA_DIR:-logs/qa/$(date +%Y%m%d)}

a() { timeout "${ADB_TIMEOUT:-30}" "$ADB" "$@"; }
sh_() { a shell "$@" | tr -d '\r'; }

# Cây giao diện (uiautomator). Flutter chỉ lộ chữ qua Semantics: nút không nhãn = lỗi truy cập.
# Xoá tệp cũ trước: dump lỗi/hết giờ mà vẫn `cat` thì đọc phải cây CŨ và tap_text bấm nhầm toạ độ (23/11: bấm trúng
# "Tạm dừng" thay vì "Bắt đầu đo").
dump() {
  local x
  x=$(sh_ 'rm -f /sdcard/u.xml; uiautomator dump /sdcard/u.xml >/dev/null 2>&1; cat /sdcard/u.xml 2>/dev/null')
  [ -n "$x" ] || { echo "uiautomator dump thất bại" >&2; return 1; }
  printf '%s\n' "$x"
}

# App Sound Db có đang ở trước không (ảnh chụp khi app khác ở trước có thể lộ dữ liệu cá nhân của chủ máy).
app_fg() { sh_ dumpsys activity activities | grep -m1 -E 'mResumedActivity|topResumedActivity' | grep -q "$PKG/"; }

# uiautomator đặt giá trị thuộc tính trong nháy ĐƠN khi nó chứa dấu " (vd. nhãn phiên `<b>x</b>&"y`) ⇒ mọi mẫu
# phải nhận cả hai kiểu nháy, nếu không các dòng đó biến mất im lặng khỏi texts/tap_text (đo 23/11/2026).
# Toạ độ tâm của nút đầu tiên có text hoặc content-desc khớp (biểu thức chính quy grep -E).
center_of() {
  local b
  b=$(dump | grep -oE "<node [^>]*(text|content-desc)=(\"[^\"]*$1[^\"]*\"|'[^']*$1[^']*')[^>]*>" | head -1 \
    | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | grep -oE '[0-9]+' | tr '\n' ' ')
  [ -z "$b" ] && return 1
  read -r x1 y1 x2 y2 <<<"$b"
  echo "$(((x1 + x2) / 2)) $(((y1 + y2) / 2))"
}

tap_text() {
  local xy
  xy=$(center_of "$1") || { echo "không thấy: $1" >&2; return 1; }
  # shellcheck disable=SC2086
  sh_ input tap $xy
}

wait_text() {
  local i
  for ((i = 0; i < ${2:-10}; i++)); do
    dump | grep -qE "(text|content-desc)=(\"[^\"]*$1|'[^']*$1)" && return 0
    sleep 1
  done
  echo "hết giờ chờ: $1" >&2
  return 1
}

# Danh sách chữ đang hiện (để đối chiếu nhanh, không cần ảnh).
texts() {
  dump | grep -oE "(text|content-desc)=(\"[^\"]+\"|'[^']+')" | sed -E "s/^[a-z-]+=[\"']//; s/[\"']\$//" | awk 'NF'
}

shot() {
  app_fg || { echo "Sound Db không ở trước - không chụp: $1" >&2; return 1; }
  mkdir -p "$QA_DIR"
  a exec-out screencap -p >"$QA_DIR/$1.png" && echo "$QA_DIR/$1.png"
}

log_app() { sh_ "logcat -d --pid=\$(pidof $PKG)"; }
start_app() { sh_ am start -W -n "$PKG/.MainActivity"; }
