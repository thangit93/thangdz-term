# default — minimal prompt: ➜ dir (branch) ✗
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr ' ✗'
zstyle ':vcs_info:*' stagedstr ' ✚'
zstyle ':vcs_info:git:*' formats ' %F{cyan}(%F{red}%b%F{yellow}%u%c%F{cyan})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{cyan}(%F{red}%b%F{yellow}|%a%F{cyan})%f'

prompt_precmd() { vcs_info }
precmd_functions+=(prompt_precmd)

setopt PROMPT_SUBST
PROMPT='%(?.%F{green}.%F{red})➜%f %F{cyan}%c%f${vcs_info_msg_0_} '
