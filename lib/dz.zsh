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
    path)
      echo "$MY_ZSH"
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
  dz update    Pull the latest config from remote and reload the shell
  dz reload    Restart the shell
  dz doctor    Health check: symlink, plugins, theme, remote
  dz path      Print the repo directory
  dz help      Show this help
EOF
}

function _dz_update() {
  if [[ ! -d "$MY_ZSH/.git" ]]; then
    echo "dz: no git repo found at $MY_ZSH" >&2
    echo "    Did you install by copying instead of git clone?" >&2
    return 1
  fi

  echo "thangdz-term: updating..."
  local prev_head
  prev_head=$(git -C "$MY_ZSH" rev-parse --short HEAD)

  if git -C "$MY_ZSH" pull --rebase --stat; then
    local new_head
    new_head=$(git -C "$MY_ZSH" rev-parse --short HEAD)
    if [[ "$prev_head" != "$new_head" ]]; then
      echo ""
      echo "Updated $prev_head → $new_head"
      echo "Reloading shell..."
      exec zsh
    else
      echo ""
      echo "Already up to date ($new_head)"
    fi
  else
    echo ""
    echo "Update failed. Try:
  cd $MY_ZSH && git stash && dz update" >&2
    return 1
  fi
}

function _dz_doctor() {
  local ok=true

  echo "thangdz-term doctor"
  echo "==================="

  echo -n "MY_ZSH ... "
  if [[ -n "${MY_ZSH:-}" && -d "$MY_ZSH" ]]; then
    echo "$MY_ZSH ✓"
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
  if [[ -f "$MY_ZSH/init.zsh" ]]; then
    echo "✓"
  else
    echo "missing ✗"; ok=false
  fi

  echo -n "theme ($ZSH_THEME) ... "
  if [[ -f "$MY_ZSH/themes/${ZSH_THEME}.zsh" ]]; then
    echo "✓"
  else
    echo "missing $MY_ZSH/themes/${ZSH_THEME}.zsh ✗"; ok=false
  fi

  for _p in ${plugins[@]}; do
    echo -n "plugin $_p ... "
    if [[ -f "$MY_ZSH/plugins/$_p/$_p.plugin.zsh" || -f "$MY_ZSH/plugins/$_p/$_p.zsh" ]]; then
      echo "✓"
    else
      echo "missing ✗"; ok=false
    fi
  done

  echo -n "git remote ... "
  local remote
  remote=$(git -C "$MY_ZSH" remote get-url origin 2>/dev/null || true)
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
