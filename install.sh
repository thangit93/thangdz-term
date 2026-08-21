#!/usr/bin/env bash
# Install: back up old rc files, then symlink them into this repo
# Usage: ./install.sh [zsh|bash|all]   (default: your current login shell)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  TARGET="$(basename "${SHELL:-zsh}")"
  case "$TARGET" in
    zsh*|bash*) ;;
    *) TARGET=zsh ;;
  esac
fi

link_one() {
  local rc="$1" target_file="$2"
  if [[ "$(readlink "$rc" 2>/dev/null || true)" == "$target_file" ]]; then
    echo "Already installed: $rc -> $target_file"
    return
  fi
  if [[ -e "$rc" || -L "$rc" ]]; then
    local backup="$rc.pre-thangdz-term.$(date +%Y%m%d%H%M%S)"
    mv "$rc" "$backup"
    echo "Backed up old $rc -> $backup"
  fi
  ln -s "$target_file" "$rc"
  echo "Symlinked: $rc -> $target_file"
}

case "$TARGET" in
  zsh)
    link_one "$HOME/.zshrc" "$REPO_DIR/zshrc"
    ;;
  bash)
    link_one "$HOME/.bashrc" "$REPO_DIR/bashrc"
    # Login bash shells read .bash_profile, not .bashrc — make sure it sources ours
    if [[ -f "$HOME/.bash_profile" ]] && ! grep -qE '(^|[[:space:]])(source|\.) .*(\.bashrc|bashrc)' "$HOME/.bash_profile"; then
      printf '\n# thangdz-term: load .bashrc in login shells\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$HOME/.bash_profile"
      echo "Added .bashrc sourcing to ~/.bash_profile"
    fi
    ;;
  all)
    link_one "$HOME/.zshrc" "$REPO_DIR/zshrc"
    link_one "$HOME/.bashrc" "$REPO_DIR/bashrc"
    if [[ -f "$HOME/.bash_profile" ]] && ! grep -qE '(^|[[:space:]])(source|\.) .*(\.bashrc|bashrc)' "$HOME/.bash_profile"; then
      printf '\n# thangdz-term: load .bashrc in login shells\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$HOME/.bash_profile"
      echo "Added .bashrc sourcing to ~/.bash_profile"
    fi
    ;;
  *)
    echo "Usage: ./install.sh [zsh|bash|all]"
    exit 1
    ;;
esac

echo "Done ($TARGET). Open a new terminal or restart your shell."
