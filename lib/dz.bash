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
