# thangdz-term — main bash config (symlinked to ~/.bashrc)
# After editing, run `exec bash` or open a new terminal to apply.

# Locate the repo directory (bash has no symlink-resolving modifier, so try known paths)
if [[ -z "${THANGDZ:-}" ]]; then
  for _d in "$HOME/Projects/thangdz-term" "$HOME/.thangdz-term" "$HOME/thangdz-term"; do
    if [[ -f "$_d/init.bash" ]]; then
      export THANGDZ="$_d"
      break
    fi
  done
fi
# Cloned somewhere else? Set it manually: export THANGDZ="/path/to/thangdz-term"
export THANGDZ="${THANGDZ:-$HOME/Projects/thangdz-term}"

# Theme (themes/<name>.bash)
BASH_THEME="default"

# Load the framework
source "$THANGDZ/init.bash"

# ==================== Personal config ====================

alias pj="cd ~/Projects"
