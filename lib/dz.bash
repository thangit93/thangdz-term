# dz — CLI for managing thangdz-term (bash version)
dz() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    _dz_help
    return 1
  fi

  case "$cmd" in
    update)
      _dz_update
      ;;
    reload)
      exec bash
      ;;
    doctor)
      _dz_doctor
      ;;
    uninstall)
      _dz_uninstall
      ;;
    games)
      _dz_games
      ;;
    game)
      shift
      _dz_game "$@"
      ;;
    path)
      echo "$THANGDZ"
      ;;
    logo)
      shift
      if [[ $# -gt 0 ]]; then
        command figlet "$@" 2>/dev/null || cat "$THANGDZ/lib/logo.txt"
      else
        cat "$THANGDZ/lib/logo.txt"
      fi
      ;;
    help|--help|-h)
      _dz_help
      ;;
    *)
      echo "dz: unknown command '$cmd'" >&2
      _dz_help
      return 1
      ;;
  esac
}

_dz_help() {
  cat <<'EOF'
dz — manage thangdz-term

Usage:
  dz update    Pull the latest config from remote and reload the shell
  dz reload    Restart the shell
  dz doctor    Health check: symlink, theme, remote
  dz uninstall Remove thangdz-term: restore your old ~/.bashrc, leave the repo
  dz games     List the bundled terminal mini-games
  dz game <n>  Play mini-game number <n> (see: dz games)
  dz path      Print the repo directory
  dz logo      Print the ThangDZ logo (or: dz logo <text> renders via figlet)
  dz help      Show this help
EOF
}

_dz_update() {
  if [[ ! -d "$THANGDZ/.git" ]]; then
    echo "dz: no git repo found at $THANGDZ" >&2
    echo "    Did you install by copying instead of git clone?" >&2
    return 1
  fi

  echo "thangdz-term: updating..."
  local prev_head
  prev_head=$(git -C "$THANGDZ" rev-parse --short HEAD)

  if git -C "$THANGDZ" pull --rebase --stat; then
    local new_head
    new_head=$(git -C "$THANGDZ" rev-parse --short HEAD)
    echo ""
    if [[ "$prev_head" != "$new_head" ]]; then
      echo "Updated $prev_head → $new_head"
    else
      echo "Already up to date ($new_head) - reloading anyway"
    fi
    echo "Reloading shell..."
    exec bash
  else
    echo ""
    echo "Update failed. Try:
  cd $THANGDZ && git stash && dz update" >&2
    return 1
  fi
}

_dz_doctor() {
  local ok=true

  echo "thangdz-term doctor (bash)"
  echo "========================="

  echo -n "THANGDZ ... "
  if [[ -n "${THANGDZ:-}" && -d "$THANGDZ" ]]; then
    echo "$THANGDZ ✓"
  else
    echo "not set ✗"; ok=false
  fi

  echo -n "~/.bashrc symlink ... "
  local target
  target=$(readlink ~/.bashrc 2>/dev/null || true)
  if [[ -n "$target" ]]; then
    echo "$target ✓"
  else
    echo "not a symlink (copy?) ✗"; ok=false
  fi

  echo -n "init.bash ... "
  if [[ -f "$THANGDZ/init.bash" ]]; then
    echo "✓"
  else
    echo "missing ✗"; ok=false
  fi

  echo -n "theme ($BASH_THEME) ... "
  if [[ -f "$THANGDZ/themes/${BASH_THEME}.bash" ]]; then
    echo "✓"
  else
    echo "missing $THANGDZ/themes/${BASH_THEME}.bash ✗"; ok=false
  fi

  echo -n "git remote ... "
  local remote
  remote=$(git -C "$THANGDZ" remote get-url origin 2>/dev/null || true)
  if [[ -n "$remote" ]]; then
    echo "$remote ✓"
  else
    echo "not set ✗"; ok=false
  fi

  echo ""
  if $ok; then
    echo "All good! 🎉"
  else
    echo "Some checks failed — see the ✗ items above."
    return 1
  fi
}

_dz_uninstall() {
  echo "This will remove thangdz-term from your shell:"
  echo "  - restore your old ~/.bashrc from backup (if found), or just remove the symlink"
  echo "  - the repo at $THANGDZ is left on disk — delete it yourself if you want"
  echo "  - note: if install.sh added a sourcing line to ~/.bash_profile, remove it manually"
  echo ""
  read -r -p "Continue? [y/N] " _reply
  if [[ "$_reply" != "y" && "$_reply" != "Y" ]]; then
    echo "Aborted."
    return 1
  fi

  local rc="$HOME/.bashrc"
  local link_target
  link_target=$(readlink "$rc" 2>/dev/null || true)
  if [[ -z "$link_target" ]]; then
    echo "dz: $rc is not a symlink — leaving it alone." >&2
  else
    rm "$rc"
    local backup
    backup=$(ls -t "$rc".pre-thangdz-term.* 2>/dev/null | head -n1 || true)
    if [[ -n "$backup" ]]; then
      mv "$backup" "$rc"
      echo "Restored $rc from $backup"
    else
      echo "Removed symlink $rc (no backup found — you now have no ~/.bashrc)"
    fi
  fi

  echo ""
  echo "Repo left at: $THANGDZ"
  echo "  Remove it yourself if you want:  rm -rf \"$THANGDZ\""
  echo "Open a new terminal to finish."
}

_dz_games() {
  echo "🕹️  Mini-games — chơi bằng: dz game <số>"
  echo ""
  local f num title desc
  for f in "$THANGDZ"/games/[0-9][0-9]-*.sh; do
    [[ -e "$f" ]] || continue
    num=$(basename "$f" | cut -d- -f1)
    title=$(grep -m1 '^# title:' "$f" | sed 's/^# title: *//')
    desc=$(grep -m1 '^# desc:' "$f" | sed 's/^# desc: *//')
    printf "  %s) %-24s %s\n" "$num" "$title" "$desc"
  done
}

_dz_game() {
  local n="${1:-}"
  if [[ -z "$n" ]]; then
    echo "Usage: dz game <số>   (xem: dz games)" >&2
    return 1
  fi
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    echo "dz: số không hợp lệ: $n" >&2
    return 1
  fi
  local padded
  padded=$(printf "%02d" "$n")
  local f
  f=$(ls "$THANGDZ"/games/"$padded"-*.sh 2>/dev/null | head -n1)
  if [[ -z "$f" ]]; then
    echo "dz: không tìm thấy game #$n — xem: dz games" >&2
    return 1
  fi
  bash "$f"
}
