#!/usr/bin/env bash
# QA-11: CPU (jiffies/giây, 100 = một lõi) của gói .profile theo tab khi đang đo. Dùng: scripts/android/qa11-cpu.sh <nhãn> [số vòng]
# Toạ độ cho màn 1080x2400 (SM-M325FV): tab ở y=2113, Bắt đầu đo 867,156, Tạm dừng 875,157. Kết quả: $QA_DIR (bị .gitignore).
set -u
cd "$(dirname "$0")/../.."
source scripts/android/ui.sh
PKG=com.tsudev.sounddb.profile
mkdir -p "$QA_DIR"; out=$QA_DIR/qa11-cpu-$1.tsv
sh_ am force-stop $PKG; sleep 1
sh_ monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 5
app_fg || { echo "app không ở trước" >&2; exit 1; }
sh_ input tap 108 2113; sleep 2
printf 'vong\ttab\tjiffies_s\tthoi_diem\n' > "$out"
printf '0\tyen_chua_do\t%s\t%s\n' "$(cpu_rate 20)" "$(date +%T)" >> "$out"
sh_ input tap 867 156; sleep 5   # Bắt đầu đo
for v in $(seq 1 "${2:-2}"); do
  for t in "108 do_muc" "324 phan_tich" "540 bo_chinh_am" "972 cai_dat"; do
    set -- $t
    sh_ input tap "$1" 2113; sleep 6
    app_fg || { echo "app rời màn trước" >&2; exit 1; }
    printf '%s\t%s\t%s\t%s\n' "$v" "$2" "$(cpu_rate 20)" "$(date +%T)" >> "$out"
  done
done
sh_ input tap 108 2113; sleep 2; sh_ input tap 875 157   # Tạm dừng
cat "$out"
