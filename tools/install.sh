#!/usr/bin/env bash
# Remote installer for thangdz-term — clones the repo and runs the local installer.
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/thangit93/thangdz-term/main/tools/install.sh)"
set -euo pipefail

REPO_URL="${THANGDZ_REPO:-https://github.com/thangit93/thangdz-term.git}"
DIR="${THANGDZ_DIR:-$HOME/Projects/thangdz-term}"

command -v git >/dev/null 2>&1 || { echo "thangdz-term: git is required"; exit 1; }

if [[ -d "$DIR/.git" ]]; then
  echo "Found existing repo at $DIR - pulling latest..."
  git -C "$DIR" pull --rebase --autostash
else
  mkdir -p "$(dirname "$DIR")"
  git clone "$REPO_URL" "$DIR"
fi

bash "$DIR/install.sh"

if [[ -t 0 ]]; then
  echo "Starting a fresh zsh..."
  exec zsh
else
  echo "Done. Open a new terminal or run: exec zsh"
fi
