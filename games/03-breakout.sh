#!/usr/bin/env bash
# title: Breakout
# desc: Smash every brick — bounce the ball off the paddle, arrows or a/d
#
# Same real-time trick as Catch the Ball: macOS ships bash 3.2, whose
# `read -t` takes only whole seconds and whose `read -n` forces the tty back
# into blocking mode, so neither can poll between frames. The tty is left
# fully non-blocking (min 0 time 0), each frame drains buffered keys with one
# `dd`, and the external `sleep` paces the frames — the ball keeps moving
# whether or not a key is pressed.
#
# Rows are assembled by splicing into a pre-built blank line instead of
# appending cell by cell, which keeps a big field cheap to redraw in bash.
set -uo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "Breakout needs an interactive terminal — skipping."
  exit 1
fi

# ---- field size: fill the window, within sane bounds -----------------------
BRICK_W=4
size=$(stty size 2>/dev/null || echo "")
rows=${size%% *}
cols=${size##* }
[[ "$rows" =~ ^[0-9]+$ ]] && (( rows > 12 )) || rows=24
[[ "$cols" =~ ^[0-9]+$ ]] && (( cols > 30 )) || cols=80

WIDTH=$(( cols - 4 ))
(( WIDTH > 120 )) && WIDTH=120
(( WIDTH < 32 )) && WIDTH=32
WIDTH=$(( (WIDTH / BRICK_W) * BRICK_W ))

HEIGHT=$(( rows - 8 ))
(( HEIGHT > 36 )) && HEIGHT=36
(( HEIGHT < 14 )) && HEIGHT=14

BRICK_ROWS=5
BRICK_TOP=1
BCOLS=$(( WIDTH / BRICK_W ))
PADDLE_W=$(( WIDTH / 5 ))
(( PADDLE_W < 6 )) && PADDLE_W=6
PADDLE_STEP=2
PADDLE_ROW=$(( HEIGHT - 1 ))

# The ball steps once per frame, so the frame delay *is* the ball speed;
# clearing bricks shortens it.
SPEEDS=(0.040 0.034 0.028 0.024 0.020)
level=0
FRAME=${SPEEDS[0]}

score=0
lives=3
left=$(( BRICK_ROWS * BCOLS ))
quit=false
won=false

pcol=$(( (WIDTH - PADDLE_W) / 2 ))
brow=$(( HEIGHT - 3 ))
bcol=$(( WIDTH / 2 ))
drow=-1
dcol=1

# bricks[r * BCOLS + i] — 1 alive, 0 broken (every index set up front so
# `set -u` never trips on an unset element)
bricks=()
for (( r = 0; r < BRICK_ROWS; r++ )); do
  for (( i = 0; i < BCOLS; i++ )); do
    bricks[r * BCOLS + i]=1
  done
done

BLANK=""
for (( c = 0; c < WIDTH; c++ )); do BLANK+=" "; done
BORDER="+"
for (( c = 0; c < WIDTH; c++ )); do BORDER+="-"; done
BORDER+="+"
PADDLE_STR=""
for (( c = 0; c < PADDLE_W; c++ )); do PADDLE_STR+="="; done

COLORS=($'\033[91m' $'\033[93m' $'\033[92m' $'\033[96m' $'\033[95m')
RESET=$'\033[0m'

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

draw() {
  local buf r i line color brow_in_bricks
  buf=$'\033[H'
  buf+=$(printf 'Breakout    score: %-5d lives: %d   bricks left: %-4d' \
    "$score" "$lives" "$left")
  buf+=$'\n'"  arrows or a/d to move, q to quit"$'\n'
  buf+="$BORDER"$'\n'

  for (( r = 0; r < HEIGHT; r++ )); do
    color=""
    brow_in_bricks=$(( r - BRICK_TOP ))
    if (( brow_in_bricks >= 0 && brow_in_bricks < BRICK_ROWS )); then
      line=""
      for (( i = 0; i < BCOLS; i++ )); do
        if (( bricks[brow_in_bricks * BCOLS + i] )); then
          line+="[##]"
        else
          line+="    "
        fi
      done
      color="${COLORS[brow_in_bricks % 5]}"
    else
      line="$BLANK"
    fi

    if (( r == PADDLE_ROW )); then
      line="${line:0:pcol}${PADDLE_STR}${line:pcol + PADDLE_W}"
    fi
    if (( r == brow )); then
      line="${line:0:bcol}O${line:bcol + 1}"
    fi

    if [[ -n "$color" ]]; then
      buf+="|${color}${line}${RESET}|"$'\n'
    else
      buf+="|${line}|"$'\n'
    fi
  done

  buf+="$BORDER"$'\n'
  printf '%s' "$buf"
}

move_right() { pcol=$(( pcol + PADDLE_STEP )); (( pcol > WIDTH - PADDLE_W )) && pcol=$(( WIDTH - PADDLE_W )); return 0; }
move_left()  { pcol=$(( pcol - PADDLE_STEP )); (( pcol < 0 )) && pcol=0; return 0; }

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
      i=$(( i + 3 ))
      continue
    fi
    case "$c" in
      d|D|l) move_right ;;
      a|A|h) move_left ;;
      q|Q) quit=true; return 0 ;;
    esac
    i=$(( i + 1 ))
  done
}

reset_ball() {
  brow=$(( HEIGHT - 3 ))
  bcol=$(( WIDTH / 2 ))
  drow=-1
  dcol=1
  (( RANDOM % 2 )) && dcol=-1
  return 0
}

# Break the brick at (row, col) if one is there; 0 when it hit something.
hit_brick() {
  local r="$1" c="$2" br idx
  br=$(( r - BRICK_TOP ))
  (( br < 0 || br >= BRICK_ROWS )) && return 1
  idx=$(( br * BCOLS + c / BRICK_W ))
  (( bricks[idx] )) || return 1
  bricks[idx]=0
  score=$(( score + 1 ))
  left=$(( left - 1 ))
  if (( score % 12 == 0 && level < ${#SPEEDS[@]} - 1 )); then
    level=$(( level + 1 ))
    FRAME=${SPEEDS[level]}
  fi
  return 0
}

step_ball() {
  local nr nc hit_pos
  nc=$(( bcol + dcol ))
  if (( nc < 0 || nc >= WIDTH )); then
    dcol=$(( -dcol ))
    nc=$(( bcol + dcol ))
  fi
  nr=$(( brow + drow ))
  if (( nr < 0 )); then
    drow=$(( -drow ))
    nr=$(( brow + drow ))
  fi

  # paddle
  if (( nr >= PADDLE_ROW )); then
    if (( nc >= pcol && nc < pcol + PADDLE_W )); then
      drow=-1
      hit_pos=$(( nc - pcol ))
      if (( hit_pos < PADDLE_W / 3 )); then
        dcol=-1
      elif (( hit_pos >= 2 * PADDLE_W / 3 )); then
        dcol=1
      fi
      nr=$(( PADDLE_ROW - 1 ))
    else
      lives=$(( lives - 1 ))
      reset_ball
      return 0
    fi
  fi

  # bricks — check the destination, then the two axis-aligned neighbours so
  # a diagonal approach can't slip between two bricks
  if hit_brick "$nr" "$nc"; then
    drow=$(( -drow ))
    nr=$(( brow + drow ))
  elif hit_brick "$brow" "$nc"; then
    dcol=$(( -dcol ))
    nc=$bcol
  elif hit_brick "$nr" "$bcol"; then
    drow=$(( -drow ))
    nr=$brow
  fi

  brow=$nr
  bcol=$nc
  return 0
}

while (( lives > 0 )) && ! $quit; do
  draw
  sleep "$FRAME"
  handle_keys
  $quit && break

  step_ball
  if (( left == 0 )); then
    won=true
    break
  fi
done

draw
printf '\033[2J\033[H'
if $won; then
  echo "You cleared every brick! Final score: $score"
else
  echo "Game over — final score: $score  (bricks left: $left)"
fi
