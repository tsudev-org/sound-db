#!/usr/bin/env bash
# QA-11: hồ sơ một tab khi đang đo - CPU theo luồng (thr.sh, 20 s) + hồ sơ CPU Dart của isolate UI (cpu-profile.mjs, 10 s).
# Dùng: scripts/android/qa11-profile.sh <nhãn> [x của tab, mặc định 108 = Đo mức]. Gói .profile, màn 1080x2400.
# Kết quả: $QA_DIR/qa11-thr-<nhãn>.txt + $QA_DIR/qa11-prof-<nhãn>.txt (bị .gitignore - chép số vào phiếu 06).
set -u
cd "$(dirname "$0")/../.."
source scripts/android/ui.sh
PKG=com.tsudev.sounddb.profile
mkdir -p "$QA_DIR"
sh_ logcat -c
sh_ am force-stop $PKG; sleep 1
sh_ monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 5
app_fg || { echo "app không ở trước" >&2; exit 1; }
sh_ input tap 108 2113; sleep 2
sh_ input tap 867 156; sleep 3   # Bắt đầu đo
sh_ input tap "${2:-108}" 2113; sleep 6
pid=$(sh_ pidof $PKG)
a push scripts/android/thr.sh /data/local/tmp/thr.sh >/dev/null
sh_ sh /data/local/tmp/thr.sh "$pid" | sort > "$QA_DIR/.t1"
sleep 20
sh_ sh /data/local/tmp/thr.sh "$pid" | sort > "$QA_DIR/.t2"
join "$QA_DIR/.t1" "$QA_DIR/.t2" | awk '{d=($5-$3)/20; if (d>0) printf "%6.1f %s\n", d, $2}' | sort -rn > "$QA_DIR/qa11-thr-$1.txt"
# VM service của bản profile in vào logcat; forward cùng cổng sang localhost Windows.
uri=$(sh_ logcat -d | grep -oE 'http://127\.0\.0\.1:[0-9]+/[^ ]+/' | tail -1)
if [ -n "$uri" ]; then
  port=$(echo "$uri" | sed -E 's#http://127.0.0.1:([0-9]+)/.*#\1#')
  a forward "tcp:$port" "tcp:$port" >/dev/null
  ws="ws://127.0.0.1:$port/${uri#http://127.0.0.1:$port/}ws"
  node.exe "$(wslpath -w scripts/android/cpu-profile.mjs)" "$ws" 10 "${TOP:-30}" > "$QA_DIR/qa11-prof-$1.txt" 2>&1
  a forward --remove "tcp:$port" >/dev/null
else
  echo "không thấy VM service trong logcat" > "$QA_DIR/qa11-prof-$1.txt"
fi
sh_ input tap 108 2113; sleep 2; sh_ input tap 875 157   # Tạm dừng
head -12 "$QA_DIR/qa11-thr-$1.txt"
head -45 "$QA_DIR/qa11-prof-$1.txt"
