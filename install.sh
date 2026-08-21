#!/usr/bin/env bash
# Install: back up the old .zshrc, then symlink ~/.zshrc -> this repo
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC="$HOME/.zshrc"

if [[ "$(readlink "$ZSHRC" 2>/dev/null || true)" == "$REPO_DIR/zshrc" ]]; then
  echo "Already installed: $ZSHRC -> $REPO_DIR/zshrc"
  exit 0
fi

if [[ -e "$ZSHRC" || -L "$ZSHRC" ]]; then
  backup="$ZSHRC.pre-thangdz-term.$(date +%Y%m%d%H%M%S)"
  mv "$ZSHRC" "$backup"
  echo "Backed up old .zshrc -> $backup"
fi

ln -s "$REPO_DIR/zshrc" "$ZSHRC"
echo "Symlinked: $ZSHRC -> $REPO_DIR/zshrc"
echo "Done. Open a new terminal or run: exec zsh"
