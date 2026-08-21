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

# Field size: fill the window, within sane bounds
size=$(stty size 2>/dev/null || echo "")
term_rows=${size%% *}
term_cols=${size##* }
[[ "$term_rows" =~ ^[0-9]+$ ]] && (( term_rows > 12 )) || term_rows=24
[[ "$term_cols" =~ ^[0-9]+$ ]] && (( term_cols > 30 )) || term_cols=80

WIDTH=$(( term_cols - 4 ))
(( WIDTH > 120 )) && WIDTH=120
(( WIDTH < 32 )) && WIDTH=32
HEIGHT=$(( term_rows - 7 ))
(( HEIGHT > 36 )) && HEIGHT=36
(( HEIGHT < 12 )) && HEIGHT=12

PADDLE=$(( WIDTH / 5 ))
(( PADDLE < 6 )) && PADDLE=6

# The ball drops one row per frame, so the frame delay *is* the fall speed;
# every few catches shortens it. The paddle covers PADDLE_SPEED cells in that
# same frame, so it always outruns the ball by that factor whatever the speed.
SPEEDS=(0.065 0.055 0.046 0.038 0.032)
level=0
FRAME=${SPEEDS[0]}

# A terminal never reports key *releases*, and auto-repeat only starts after
# the OS repeat delay (~0.5s), so a fixed step per keypress can't keep up with
# the ball. A keypress instead sets a direction and the paddle glides on for
# PADDLE_COAST frames; holding the key refreshes it into continuous motion.
PADDLE_SPEED=3
PADDLE_COAST=5
pdir=0
pcoast=0

score=0
lives=3
pcol=$(( (WIDTH - PADDLE) / 2 ))
bcol=$(( RANDOM % WIDTH ))
brow=0
quit=false

# Pre-built row pieces: splicing into a blank line keeps a redraw O(rows)
# instead of O(rows * cols), which matters once the field fills the window.
BLANK=""
for (( c = 0; c < WIDTH; c++ )); do BLANK+=" "; done
BORDER="+"
for (( c = 0; c < WIDTH; c++ )); do BORDER+="-"; done
BORDER+="+"
PADDLE_STR=""
for (( c = 0; c < PADDLE; c++ )); do PADDLE_STR+="="; done

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
  local buf r line
  buf=$'\033[H'
  buf+=$(printf 'Catch the Ball   score: %-4d lives: %d' "$score" "$lives")
  buf+=$'\n'"  arrows or a/d to move, q to quit  "$'\n'
  buf+="$BORDER"$'\n'
  for (( r = 0; r < HEIGHT; r++ )); do
    line="$BLANK"
    if (( r == HEIGHT - 1 )); then
      line="${line:0:pcol}${PADDLE_STR}${line:pcol + PADDLE}"
    fi
    if (( r == brow )); then
      line="${line:0:bcol}o${line:bcol + 1}"
    fi
    buf+="|${line}|"$'\n'
  done
  buf+="$BORDER"$'\n'
  printf '%s' "$buf"
}

move_right() { pdir=1;  pcoast=$PADDLE_COAST; return 0; }
move_left()  { pdir=-1; pcoast=$PADDLE_COAST; return 0; }

glide_paddle() {
  (( pcoast > 0 )) || return 0
  pcol=$(( pcol + pdir * PADDLE_SPEED ))
  (( pcol < 0 )) && pcol=0
  (( pcol > WIDTH - PADDLE )) && pcol=$(( WIDTH - PADDLE ))
  pcoast=$(( pcoast - 1 ))
  return 0
}

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

  glide_paddle
  brow=$((brow + 1))
  if (( brow >= HEIGHT - 1 )); then
    if (( bcol >= pcol && bcol < pcol + PADDLE )); then
      score=$((score + 1))
      if (( score % 3 == 0 && level < ${#SPEEDS[@]} - 1 )); then
        level=$((level + 1))
        FRAME=${SPEEDS[level]}
      fi
    else
      lives=$((lives - 1))
    fi
    bcol=$(( RANDOM % WIDTH ))
    brow=0
  fi
done

printf '\033[2J\033[H'
echo "Game over — final score: $score"
