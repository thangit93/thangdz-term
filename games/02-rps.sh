#!/usr/bin/env bash
# title: Oẳn tù tì
# desc: Kéo - Búa - Bao đấu với máy, chơi nhiều vòng, gõ q để dừng
set -uo pipefail

win=0
lose=0
draw=0

echo "✊✋✌️  Oẳn tù tì — b) búa, k) kéo, l) lá | q để dừng"
echo ""

beats() {
  # $1 thắng $2 ?
  case "$1:$2" in
    b:k|k:l|l:b) return 0 ;;
    *) return 1 ;;
  esac
}

name_of() {
  case "$1" in
    b) echo "Búa" ;;
    k) echo "Kéo" ;;
    l) echo "Lá" ;;
  esac
}

while true; do
  if ! read -r -p "Chọn (b/k/l, q để dừng): " you; then
    echo ""
    break
  fi
  you=$(printf '%s' "$you" | tr '[:upper:]' '[:lower:]')
  [[ "$you" == "q" ]] && break
  if [[ "$you" != "b" && "$you" != "k" && "$you" != "l" ]]; then
    echo "  Nhập b, k, l hoặc q."
    continue
  fi

  pick=$(( RANDOM % 3 ))
  case $pick in
    0) cpu="b" ;;
    1) cpu="k" ;;
    2) cpu="l" ;;
  esac

  echo "  Bạn: $(name_of "$you")  |  Máy: $(name_of "$cpu")"

  if [[ "$you" == "$cpu" ]]; then
    echo "  🤝 Hòa!"
    draw=$((draw + 1))
  elif beats "$you" "$cpu"; then
    echo "  🎉 Bạn thắng!"
    win=$((win + 1))
  else
    echo "  😢 Bạn thua!"
    lose=$((lose + 1))
  fi
  echo ""
done

echo "Kết quả: thắng $win — thua $lose — hòa $draw"
