#!/usr/bin/env bash
# title: Đố vui toán học
# desc: Trả lời nhanh 5 phép tính cộng/trừ/nhân ngẫu nhiên
set -uo pipefail

total=5
score=0

echo "🧮 Đố vui toán học — trả lời $total câu"
echo ""

i=1
while (( i <= total )); do
  a=$(( (RANDOM % 20) + 1 ))
  b=$(( (RANDOM % 20) + 1 ))
  op_pick=$(( RANDOM % 3 ))
  case $op_pick in
    0) op="+"; answer=$(( a + b )) ;;
    1) op="-"; answer=$(( a - b )) ;;
    2) op="*"; answer=$(( a * b )) ;;
  esac

  if ! read -r -p "Câu $i/$total: $a $op $b = ? " reply; then
    echo ""
    echo "Đầu vào kết thúc — dừng game."
    exit 1
  fi

  if ! [[ "$reply" =~ ^-?[0-9]+$ ]]; then
    echo "  Không hợp lệ — coi như sai. Đáp án: $answer"
  elif (( reply == answer )); then
    echo "  ✓ Chính xác!"
    score=$((score + 1))
  else
    echo "  ✗ Sai rồi — đáp án đúng là $answer"
  fi
  echo ""
  i=$((i + 1))
done

echo "Kết quả: $score/$total câu đúng"
if (( score == total )); then
  echo "🏆 Xuất sắc!"
elif (( score >= (total / 2) )); then
  echo "👍 Khá đấy!"
else
  echo "💪 Cố lên nào!"
fi
