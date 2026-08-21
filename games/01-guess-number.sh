#!/usr/bin/env bash
# title: Đoán số bí mật
# desc: Đoán một số từ 1-100 trong tối đa 7 lần, có gợi ý cao/thấp
set -uo pipefail

secret=$(( (RANDOM % 100) + 1 ))
max_tries=7
tries=0

echo "🎯 Đoán số bí mật (1-100) — bạn có $max_tries lần đoán."
echo ""

while (( tries < max_tries )); do
  tries=$((tries + 1))
  if ! read -r -p "Lần $tries/$max_tries — nhập số: " guess; then
    echo ""
    echo "Đầu vào kết thúc — dừng game."
    exit 1
  fi

  if ! [[ "$guess" =~ ^-?[0-9]+$ ]]; then
    echo "  Vui lòng nhập một số nguyên."
    tries=$((tries - 1))
    continue
  fi

  if (( guess == secret )); then
    echo ""
    echo "🎉 Chính xác! Số bí mật là $secret — bạn đoán đúng sau $tries lần."
    exit 0
  elif (( guess < secret )); then
    echo "  Lớn hơn nữa 👆"
  else
    echo "  Nhỏ hơn nữa 👇"
  fi
done

echo ""
echo "💥 Hết lượt! Số bí mật là: $secret"
