#!/usr/bin/env bash
# title: Guess the Number
# desc: Guess a secret number between 1-100 in 7 tries or fewer
set -uo pipefail

secret=$(( (RANDOM % 100) + 1 ))
max_tries=7
tries=0

echo "Guess the Number (1-100) — you have $max_tries tries."
echo ""

while (( tries < max_tries )); do
  tries=$((tries + 1))
  if ! read -r -p "Try $tries/$max_tries — enter a number: " guess; then
    echo ""
    echo "Input ended — stopping game."
    exit 1
  fi

  if ! [[ "$guess" =~ ^-?[0-9]+$ ]]; then
    echo "  Please enter a whole number."
    tries=$((tries - 1))
    continue
  fi

  if (( guess == secret )); then
    echo ""
    echo "Correct! The number was $secret — you got it in $tries tries."
    exit 0
  elif (( guess < secret )); then
    echo "  Higher!"
  else
    echo "  Lower!"
  fi
done

echo ""
echo "Out of tries! The number was: $secret"
