#!/usr/bin/env bash
# title: Đoán xúc xắc chẵn/lẻ
# desc: Đoán kết quả tung xúc xắc là chẵn hay lẻ, gõ q để dừng
set -uo pipefail

win=0
lose=0
faces=("⚀" "⚁" "⚂" "⚃" "⚄" "⚅")

echo "🎲 Đoán xúc xắc chẵn/lẻ — c) chẵn, l) lẻ | q để dừng"
echo ""

while true; do
  if ! read -r -p "Đoán (c/l, q để dừng): " guess; then
    echo ""
    break
  fi
  guess=$(printf '%s' "$guess" | tr '[:upper:]' '[:lower:]')
  [[ "$guess" == "q" ]] && break
  if [[ "$guess" != "c" && "$guess" != "l" ]]; then
    echo "  Nhập c, l hoặc q."
    continue
  fi

  roll=$(( (RANDOM % 6) + 1 ))
  face="${faces[$((roll - 1))]}"
  if (( roll % 2 == 0 )); then
    result="c"
    result_txt="chẵn"
  else
    result="l"
    result_txt="lẻ"
  fi

  echo "  $face  Xúc xắc ra: $roll ($result_txt)"
  if [[ "$guess" == "$result" ]]; then
    echo "  🎉 Đoán đúng!"
    win=$((win + 1))
  else
    echo "  😢 Đoán sai!"
    lose=$((lose + 1))
  fi
  echo ""
done

echo "Kết quả: đúng $win — sai $lose"
