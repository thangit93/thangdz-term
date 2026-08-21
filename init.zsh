# thangdz-term loader — load order: lib → aliases → plugins → theme
if [[ -z "${MY_ZSH:-}" || ! -f "$MY_ZSH/init.zsh" ]]; then
  echo "thangdz-term: \$MY_ZSH does not point to the repo directory" >&2
  return 1
fi

for _f in "$MY_ZSH"/lib/*.zsh(N) "$MY_ZSH"/aliases/*.zsh(N); do
  source "$_f"
done
unset _f

for _p in ${plugins:-}; do
  if [[ -f "$MY_ZSH/plugins/$_p/$_p.plugin.zsh" ]]; then
    source "$MY_ZSH/plugins/$_p/$_p.plugin.zsh"
  elif [[ -f "$MY_ZSH/plugins/$_p/$_p.zsh" ]]; then
    source "$MY_ZSH/plugins/$_p/$_p.zsh"
  else
    echo "thangdz-term: plugin '$_p' not found in $MY_ZSH/plugins" >&2
  fi
done
unset _p

if [[ -n "${ZSH_THEME:-}" && -f "$MY_ZSH/themes/$ZSH_THEME.zsh" ]]; then
  source "$MY_ZSH/themes/$ZSH_THEME.zsh"
else
  echo "thangdz-term: theme '${ZSH_THEME:-}' not found in $MY_ZSH/themes" >&2
fi
