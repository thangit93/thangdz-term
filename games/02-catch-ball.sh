#!/usr/bin/env bash
# title: Catch the Ball
# desc: Real-time falling balls — slide the paddle with arrow keys (or a/d)
#
# Real-time animation on macOS's bash 3.2 needs a workaround: its `read -t`
# only accepts whole seconds, and `read -n` puts the tty back into blocking
# mode (VMIN=1), so neither can poll the keyboard between frames. Instead the
# tty is left fully non-blocking (min 0 time 0) and each frame grabs whatever
# keys are already buffered with a single `dd` read, while the external
# `sleep` — which does accept fractions — paces the frames. Input never gates
# the animation, so the ball keeps falling whether or not a key is pressed.
set -uo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "Catch the Ball needs an interactive terminal — skipping."
  exit 1
fi

WIDTH=32
HEIGHT=14
PADDLE=6
FRAME=0.05

score=0
lives=3
pcol=$(( (WIDTH - PADDLE) / 2 ))
bcol=$(( RANDOM % WIDTH ))
brow=0
frames=0
fall=6          # frames per row — smaller is faster
quit=false

old_stty=$(stty -g 2>/dev/null || true)

cleanup() {
  [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null
  printf '\033[?25h\n'
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

stty -echo -icanon min 0 time 0 2>/dev/null
printf '\033[2J\033[?25l'

draw() {
  local buf border r c line
  border="+"
  for (( c = 0; c < WIDTH; c++ )); do border+="-"; done
  border+="+"

  buf=$'\033[H'
  buf+=$(printf 'Catch the Ball   score: %-4d lives: %d' "$score" "$lives")
  buf+=$'\n'"  arrows or a/d to move, q to quit  "$'\n'
  buf+="$border"$'\n'
  for (( r = 0; r < HEIGHT; r++ )); do
    line="|"
    for (( c = 0; c < WIDTH; c++ )); do
      if (( r == brow && c == bcol )); then
        line+="o"
      elif (( r == HEIGHT - 1 && c >= pcol && c < pcol + PADDLE )); then
        line+="="
      else
        line+=" "
      fi
    done
    buf+="$line|"$'\n'
  done
  buf+="$border"$'\n'
  printf '%s' "$buf"
}

move_right() { (( pcol < WIDTH - PADDLE )) && pcol=$((pcol + 1)); return 0; }
move_left()  { (( pcol > 0 )) && pcol=$((pcol - 1)); return 0; }

# Drain every key buffered since the last frame; never blocks.
handle_keys() {
  local keys n i c seq
  keys=$(dd bs=64 count=1 2>/dev/null) || keys=""
  [[ -z "$keys" ]] && return 0

  n=${#keys}
  i=0
  while (( i < n )); do
    c="${keys:i:1}"
    if [[ "$c" == $'\033' ]]; then
      seq="${keys:i:3}"
      case "$seq" in
        $'\033[C') move_right ;;
        $'\033[D') move_left ;;
      esac
      i=$((i + 3))
      continue
    fi
    case "$c" in
      d|D|l) move_right ;;
      a|A|h) move_left ;;
      q|Q) quit=true; return 0 ;;
    esac
    i=$((i + 1))
  done
}

while (( lives > 0 )) && ! $quit; do
  draw
  sleep "$FRAME"
  handle_keys
  $quit && break

  frames=$((frames + 1))
  if (( frames % fall == 0 )); then
    brow=$((brow + 1))
    if (( brow >= HEIGHT - 1 )); then
      if (( bcol >= pcol && bcol < pcol + PADDLE )); then
        score=$((score + 1))
        if (( score % 3 == 0 && fall > 2 )); then
          fall=$((fall - 1))
        fi
      else
        lives=$((lives - 1))
      fi
      bcol=$(( RANDOM % WIDTH ))
      brow=0
    fi
  fi
done

printf '\033[2J\033[H'
echo "Game over — final score: $score"
