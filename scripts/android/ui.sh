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
dump() { sh_ 'uiautomator dump /sdcard/u.xml >/dev/null 2>&1; cat /sdcard/u.xml'; }

# Toạ độ tâm của nút đầu tiên có text hoặc content-desc khớp (biểu thức chính quy grep -E).
center_of() {
  local b
  b=$(dump | grep -oE "<node [^>]*(text|content-desc)=\"[^\"]*$1[^\"]*\"[^>]*>" | head -1 \
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
    dump | grep -qE "(text|content-desc)=\"[^\"]*$1" && return 0
    sleep 1
  done
  echo "hết giờ chờ: $1" >&2
  return 1
}

# Danh sách chữ đang hiện (để đối chiếu nhanh, không cần ảnh).
texts() { dump | grep -oE '(text|content-desc)="[^"]+"' | sed -E 's/^[a-z-]+="//; s/"$//' | awk 'NF' ; }

shot() {
  mkdir -p "$QA_DIR"
  a exec-out screencap -p >"$QA_DIR/$1.png" && echo "$QA_DIR/$1.png"
}

log_app() { sh_ "logcat -d --pid=\$(pidof $PKG)"; }
start_app() { sh_ am start -W -n "$PKG/.MainActivity"; }
