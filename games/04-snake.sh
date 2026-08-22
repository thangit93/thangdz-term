#!/usr/bin/env bash
# title: Snake
# desc: Eat and grow — the walls wrap: slip out one side, come back the other
#
# Same real-time trick as Catch the Ball and Breakout: macOS ships bash 3.2,
# whose `read -t` takes only whole seconds and whose `read -n` forces the tty
# back into blocking mode, so neither can poll between frames. The tty is left
# fully non-blocking (min 0 time 0), each frame drains buffered keys with one
# `dd`, and the external `sleep` paces the frames.
#
# The walls are not fatal: stepping off one edge mirrors the head onto the
# opposite edge, so the only way to lose is biting your own tail. Rows are
# built by splicing into pre-built blank lines, and coloured per cell with
# whole-row pattern substitution — no offset bookkeeping for escape codes.
set -uo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "Snake needs an interactive terminal — skipping."
  exit 1
fi

# ---- field size: fill the window, within sane bounds -----------------------
size=$(stty size 2>/dev/null || echo "")
rows=${size%% *}
cols=${size##* }
[[ "$rows" =~ ^[0-9]+$ ]] && (( rows > 12 )) || rows=24
[[ "$cols" =~ ^[0-9]+$ ]] && (( cols > 30 )) || cols=80

WIDTH=$(( cols - 4 ))
(( WIDTH > 120 )) && WIDTH=120
(( WIDTH < 32 )) && WIDTH=32

HEIGHT=$(( rows - 8 ))
(( HEIGHT > 36 )) && HEIGHT=36
(( HEIGHT < 14 )) && HEIGHT=14

BLANK=""
for (( c = 0; c < WIDTH; c++ )); do BLANK+=" "; done
BORDER="+"
for (( c = 0; c < WIDTH; c++ )); do BORDER+="-"; done
BORDER+="+"

HEAD_C=$'\033[92m'
BODY_C=$'\033[32m'
FOOD_C=$'\033[91m'
RESET=$'\033[0m'

# The snake steps once per tick, so the frame delay *is* the speed; every
# third food shortens it.
SPEEDS=(0.13 0.11 0.09 0.075 0.065 0.055)
level=0
FRAME=${SPEEDS[0]}

score=0
eaten=0
quit=false
dead=false
won=false

# head first, tail last
mid=$(( HEIGHT / 2 ))
start=$(( WIDTH / 4 ))
(( start < 4 )) && start=4
srow=("$mid" "$mid" "$mid" "$mid")
scol=("$start" "$((start - 1))" "$((start - 2))" "$((start - 3))")
drow=0
dcol=1

fr=0
fc=0

screen=()

old_stty=$(stty -g 2>/dev/null || true)
cleanup() {
  [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null
  printf '\033[?25h%s\n' "$RESET"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

stty -echo -icanon min 0 time 0 2>/dev/null
printf '\033[2J\033[?25l'

# Drop the food on any cell the snake is not occupying.
place_food() {
  local i
  while :; do
    fr=$(( RANDOM % HEIGHT ))
    fc=$(( RANDOM % WIDTH ))
    for (( i = 0; i < ${#srow[@]}; i++ )); do
      (( srow[i] == fr && scol[i] == fc )) && continue 2
    done
    return 0
  done
}

draw() {
  local buf r c i line
  buf=$'\033[H'
  buf+=$(printf 'Snake    score: %-5d   length: %-3d' "$score" "${#srow[@]}")
  buf+=$'\n'"  arrows or wasd to turn, q to quit — walls wrap"$'\n'
  buf+="$BORDER"$'\n'

  for (( r = 0; r < HEIGHT; r++ )); do screen[r]=$BLANK; done

  for (( i = ${#srow[@]} - 1; i > 0; i-- )); do
    r=${srow[i]} c=${scol[i]}
    screen[r]="${screen[r]:0:c}o${screen[r]:c + 1}"
  done
  r=${srow[0]} c=${scol[0]}
  screen[r]="${screen[r]:0:c}@${screen[r]:c + 1}"
  r=$fr c=$fc
  screen[r]="${screen[r]:0:c}*${screen[r]:c + 1}"

  for (( r = 0; r < HEIGHT; r++ )); do
    line="${screen[r]//o/${BODY_C}o${RESET}}"
    line="${line//@/${HEAD_C}@${RESET}}"
    line="${line//\*/${FOOD_C}*${RESET}}"
    buf+="|$line|$"$'\n'
  done

  buf+="$BORDER"$'\n'
  printf '%s' "$buf"
}

turn() {
  local ndr="$1" ndc="$2"
  # a 180° flip would bite the neck; the collision check would catch it too,
  # but swallowing the key feels better than an instant game over
  (( ndr == -drow && ndc == -dcol )) && return 0
  drow=$ndr
  dcol=$ndc
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
        $'\033[A') turn -1 0 ;;
        $'\033[B') turn 1 0 ;;
        $'\033[C') turn 0 1 ;;
        $'\033[D') turn 0 -1 ;;
      esac
      i=$(( i + 3 ))
      continue
    fi
    case "$c" in
      w|W|k|K) turn -1 0 ;;
      s|S|j|J) turn 1 0 ;;
      d|D|l|L) turn 0 1 ;;
      a|A|h|H) turn 0 -1 ;;
      q|Q) quit=true; return 0 ;;
    esac
    i=$(( i + 1 ))
  done
}

step_snake() {
  local nr nc i len will_grow bound
  nr=$(( srow[0] + drow ))
  nc=$(( scol[0] + dcol ))

  # the walls mirror: out one side, back in the other
  (( nr < 0 )) && nr=$(( HEIGHT - 1 ))
  (( nr >= HEIGHT )) && nr=0
  (( nc < 0 )) && nc=$(( WIDTH - 1 ))
  (( nc >= WIDTH )) && nc=0

  len=${#srow[@]}
  will_grow=$(( nr == fr && nc == fc ))

  # when the tail vacates this tick, its cell is safe to enter
  bound=$(( will_grow ? len : len - 1 ))
  for (( i = 0; i < bound; i++ )); do
    if (( srow[i] == nr && scol[i] == nc )); then
      dead=true
      return 0
    fi
  done

  srow=("$nr" "${srow[@]}")
  scol=("$nc" "${scol[@]}")

  if (( will_grow )); then
    score=$(( score + 10 ))
    eaten=$(( eaten + 1 ))
    if (( eaten % 3 == 0 && level < ${#SPEEDS[@]} - 1 )); then
      level=$(( level + 1 ))
      FRAME=${SPEEDS[level]}
    fi
    if (( ${#srow[@]} == WIDTH * HEIGHT )); then
      won=true
      return 0
    fi
    place_food
  else
    len=${#srow[@]}
    unset "srow[len-1]" "scol[len-1]"
  fi
  return 0
}

place_food

while ! $dead && ! $won && ! $quit; do
  draw
  sleep "$FRAME"
  handle_keys
  $quit && break
  step_snake
done

draw
printf '\033[2J\033[H'
if $won; then
  echo "You filled the whole field! Final score: $score"
else
  echo "Game over — final score: $score  (length: ${#srow[@]})"
fi
