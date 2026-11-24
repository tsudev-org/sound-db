# CPU theo luồng của một tiến trình (QA-11). Đẩy lên máy: adb push scripts/android/thr.sh /data/local/tmp/ ; chạy:
# sh /data/local/tmp/thr.sh <pid>  ⇒ "tid tên jiffies(utime+stime)". mksh hiểu sai ( ) trong ${s#*(} ⇒ dùng sed.
for t in /proc/$1/task/*; do
  s=$(cat $t/stat 2>/dev/null) || continue
  n=$(echo "$s" | sed 's/^[0-9]* [(]//; s/[)] [A-Z] .*//' | tr ' ' '_')
  j=$(echo "$s" | sed 's/.*[)] //' | cut -d' ' -f12,13 | tr ' ' '+')
  echo "${t##*/} $n $((j))"
done
