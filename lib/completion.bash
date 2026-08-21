# Load bash-completion and git completion from common macOS/Linux locations
for _bc in \
  /usr/share/bash-completion/bash_completion \
  /usr/local/share/bash-completion/bash_completion \
  /opt/homebrew/share/bash-completion/bash_completion; do
  if [[ -f "$_bc" ]]; then
    source "$_bc"
    break
  fi
done
unset _bc

for _gc in \
  /usr/share/bash-completion/completions/git \
  /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash \
  /opt/homebrew/etc/bash_completion.d/git-completion.bash \
  /usr/local/etc/bash_completion.d/git-completion.bash; do
  if [[ -f "$_gc" ]]; then
    source "$_gc"
    break
  fi
done
unset _gc
