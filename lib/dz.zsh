# dz — CLI for managing thangdz-term (like omz)
function dz() {
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
      exec zsh
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

function _dz_help() {
  cat <<'EOF'
dz — manage thangdz-term

Usage:
  dz update    Hard-sync to origin/main (discards local commits), reload the shell
  dz reload    Restart the shell
  dz doctor    Health check: symlink, plugins, theme, remote
  dz uninstall Remove thangdz-term: restore your old ~/.zshrc, leave the repo
  dz games     List the bundled terminal mini-games
  dz game <n>  Play mini-game number <n> (see: dz games)
  dz path      Print the repo directory
  dz logo      Print the ThangDZ logo (or: dz logo <text> renders via figlet)
  dz help      Show this help
EOF
}

function _dz_update() {
  if [[ ! -d "$THANGDZ/.git" ]]; then
    echo "dz: no git repo found at $THANGDZ" >&2
    echo "    Did you install by copying instead of git clone?" >&2
    return 1
  fi

  echo "thangdz-term: updating..."
  local prev_head
  prev_head=$(git -C "$THANGDZ" rev-parse --short HEAD)

  if ! git -C "$THANGDZ" fetch --prune origin; then
    echo "" >&2
    echo "dz: fetch failed — check your network / remote, then retry." >&2
    return 1
  fi

  if ! git -C "$THANGDZ" rev-parse --verify -q origin/main >/dev/null; then
    echo "dz: origin/main not found — unexpected remote branch layout." >&2
    return 1
  fi

  # Uncommitted changes are stashed (not destroyed) so they can be recovered
  if [[ -n "$(git -C "$THANGDZ" status --porcelain)" ]]; then
    git -C "$THANGDZ" stash push -u -m "dz update backup $(date '+%Y-%m-%d %H:%M')" >/dev/null
    echo "Local changes stashed — recover with: git -C $THANGDZ stash pop"
  fi

  # Hard-sync: match origin/main exactly, discarding any local commits
  git -C "$THANGDZ" checkout -f -q main 2>/dev/null
  git -C "$THANGDZ" reset --hard -q origin/main

  local new_head
  new_head=$(git -C "$THANGDZ" rev-parse --short HEAD)
  echo ""
  if [[ "$prev_head" != "$new_head" ]]; then
    echo "Synced to origin/main: $prev_head → $new_head"
    if ! git -C "$THANGDZ" merge-base --is-ancestor "$prev_head" origin/main 2>/dev/null; then
      echo "Local commits discarded — recover with: git -C $THANGDZ reset $prev_head"
    fi
    echo ""
    local new_log
    new_log=$(git -C "$THANGDZ" log --oneline --no-decorate "$prev_head..$new_head" 2>/dev/null | head -n 15)
    if [[ -n "$new_log" ]]; then
      echo "What's new:"
      echo "$new_log" | sed 's/^/  /'
      local total_new
      total_new=$(git -C "$THANGDZ" rev-list --count "$prev_head..$new_head" 2>/dev/null || echo 0)
      if (( total_new > 15 )); then
        echo "  … and $((total_new - 15)) more: git -C $THANGDZ log --oneline $prev_head..$new_head"
      fi
    fi
  else
    echo "Already up to date with origin/main ($new_head) — reloading anyway"
  fi
  echo "Reloading shell..."
  exec zsh
}

function _dz_doctor() {
  local ok=true

  echo "thangdz-term doctor"
  echo "==================="

  echo -n "THANGDZ ... "
  if [[ -n "${THANGDZ:-}" && -d "$THANGDZ" ]]; then
    echo "$THANGDZ ✓"
  else
    echo "not set ✗"; ok=false
  fi

  echo -n "~/.zshrc symlink ... "
  local target
  target=$(readlink ~/.zshrc 2>/dev/null || true)
  if [[ -n "$target" ]]; then
    echo "$target ✓"
  else
    echo "not a symlink (copy?) ✗"; ok=false
  fi

  echo -n "init.zsh ... "
  if [[ -f "$THANGDZ/init.zsh" ]]; then
    echo "✓"
  else
    echo "missing ✗"; ok=false
  fi

  echo -n "theme ($ZSH_THEME) ... "
  if [[ -f "$THANGDZ/themes/${ZSH_THEME}.zsh" ]]; then
    echo "✓"
  else
    echo "missing $THANGDZ/themes/${ZSH_THEME}.zsh ✗"; ok=false
  fi

  for _p in ${plugins[@]}; do
    echo -n "plugin $_p ... "
    if [[ -f "$THANGDZ/plugins/$_p/$_p.plugin.zsh" || -f "$THANGDZ/plugins/$_p/$_p.zsh" ]]; then
      echo "✓"
    else
      echo "missing ✗"; ok=false
    fi
  done

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

function _dz_uninstall() {
  echo "This will remove thangdz-term from your shell:"
  echo "  - restore your old ~/.zshrc from backup (if found), or just remove the symlink"
  echo "  - the repo at $THANGDZ is left on disk — delete it yourself if you want"
  echo ""
  read -q "REPLY?Continue? [y/N] "
  echo ""
  if [[ "$REPLY" != "y" ]]; then
    echo "Aborted."
    return 1
  fi

  local rc="$HOME/.zshrc"
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
      echo "Removed symlink $rc (no backup found — you now have no ~/.zshrc)"
    fi
  fi

  echo ""
  echo "Repo left at: $THANGDZ"
  echo "  Remove it yourself if you want:  rm -rf \"$THANGDZ\""
  echo "Open a new terminal to finish."
}

function _dz_games() {
  echo "🕹️  Mini-games — play with: dz game <n>"
  echo ""
  local f num title desc
  for f in "$THANGDZ"/games/[0-9][0-9]-*.sh(N); do
    num=${${f:t}%%-*}
    title=$(grep -m1 '^# title:' "$f" | sed 's/^# title: *//')
    desc=$(grep -m1 '^# desc:' "$f" | sed 's/^# desc: *//')
    printf "  %s) %-24s %s\n" "$num" "$title" "$desc"
  done
}

function _dz_game() {
  local n="${1:-}"
  if [[ -z "$n" ]]; then
    echo "Usage: dz game <n>   (see: dz games)" >&2
    return 1
  fi
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    echo "dz: invalid game number: $n" >&2
    return 1
  fi
  local padded=$(printf "%02d" "$n")
  local f=("$THANGDZ"/games/"$padded"-*.sh(N))
  if [[ -z "${f[1]:-}" ]]; then
    echo "dz: no such game #$n — see: dz games" >&2
    return 1
  fi
  bash "${f[1]}"
}
