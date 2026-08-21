HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY         # share history across terminals
setopt HIST_IGNORE_ALL_DUPS  # drop duplicate commands
setopt HIST_IGNORE_SPACE     # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS    # trim redundant whitespace
setopt HIST_VERIFY           # confirm before running a command with !!
