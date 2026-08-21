# default — minimal prompt: ➜ dir (branch) ✗
__dz_git_ps1() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return
  local dirty=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    dirty=" ✗"
  fi
  printf ' (%s%s)' "$branch" "$dirty"
}

PROMPT_COMMAND='PS1="\[\e[32m\]➜\[\e[0m\] \[\e[36m\]\W\[\e[0m\]\[\e[31m\]$(__dz_git_ps1)\[\e[0m\] "'
