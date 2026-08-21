#!/usr/bin/env bash
# title: Catch the Ball
# desc: Move the paddle with arrow keys (or a/d) to catch the falling ball
#
# macOS ships bash 3.2, whose `read -t` only accepts integer seconds (no
# fractional polling), and a backgrounded reader loses the terminal as
# its stdin in a non-interactive script. So this reads one key per tick
# with a plain integer timeout — each tick is one real second, the ball
# falls one row per tick, and a keypress moves the paddle within it.
set -uo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "Catch the Ball needs an interactive terminal — skipping."
  exit 1
fi

WIDTH=20
HEIGHT=10
PADDLE_WIDTH=5

score=0
lives=3
pcol=$(( (WIDTH - PADDLE_WIDTH) / 2 ))
bcol=$(( RANDOM % WIDTH ))
brow=0

old_stty=$(stty -g 2>/dev/null || true)

cleanup() {
  [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null
  tput cnorm 2>/dev/null
  printf '\n'
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

stty -echo -icanon min 1 time 0 2>/dev/null
tput civis 2>/dev/null

new_ball() {
  bcol=$(( RANDOM % WIDTH ))
  brow=0
}

draw() {
  clear 2>/dev/null
  printf 'Catch the Ball — score: %d   lives: %d\n' "$score" "$lives"
  printf '(arrow keys or a/d to move, q to quit — one move per second)\n\n'
  local r c line
  for (( r = 0; r < HEIGHT; r++ )); do
    line=""
    for (( c = 0; c < WIDTH; c++ )); do
      if (( r == brow && c == bcol )); then
        line+="o"
      elif (( r == HEIGHT - 1 && c >= pcol && c < pcol + PADDLE_WIDTH )); then
        line+="="
      else
        line+="."
      fi
    done
    printf '%s\n' "$line"
  done
}

quit=false
while (( lives > 0 )) && ! $quit; do
  draw

  key=""
  if read -t 1 -n 1 key; then
    if [[ "$key" == $'\x1b' ]]; then
      rest=""
      read -t 1 -n 2 rest
      key+="$rest"
    fi
    case "$key" in
      $'\x1b[C'|d|D) (( pcol < WIDTH - PADDLE_WIDTH )) && pcol=$((pcol + 1)) ;;
      $'\x1b[D'|a|A) (( pcol > 0 )) && pcol=$((pcol - 1)) ;;
      q|Q) quit=true ;;
    esac
  fi
  $quit && break

  brow=$((brow + 1))
  if (( brow >= HEIGHT - 1 )); then
    if (( bcol >= pcol && bcol < pcol + PADDLE_WIDTH )); then
      score=$((score + 1))
    else
      lives=$((lives - 1))
    fi
    new_ball
  fi
done

clear
echo "Game over — final score: $score"
