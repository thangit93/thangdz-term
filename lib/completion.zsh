autoload -Uz compinit
compinit

zstyle ':completion:*' menu select                          # tab → menu, navigate with arrows
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive matching
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'no matches: %d'
