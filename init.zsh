# thangdz-term loader — load order: lib → aliases → plugins → theme
if [[ -z "${THANGDZ:-}" || ! -f "$THANGDZ/init.zsh" ]]; then
  echo "thangdz-term: \$THANGDZ does not point to the repo directory" >&2
  return 1
fi

for _f in "$THANGDZ"/lib/*.zsh(N) "$THANGDZ"/aliases/*.zsh(N); do
  source "$_f"
done
unset _f

for _p in ${plugins:-}; do
  if [[ -f "$THANGDZ/plugins/$_p/$_p.plugin.zsh" ]]; then
    source "$THANGDZ/plugins/$_p/$_p.plugin.zsh"
  elif [[ -f "$THANGDZ/plugins/$_p/$_p.zsh" ]]; then
    source "$THANGDZ/plugins/$_p/$_p.zsh"
  else
    echo "thangdz-term: plugin '$_p' not found in $THANGDZ/plugins" >&2
  fi
done
unset _p

if [[ -n "${ZSH_THEME:-}" && -f "$THANGDZ/themes/$ZSH_THEME.zsh" ]]; then
  source "$THANGDZ/themes/$ZSH_THEME.zsh"
else
  echo "thangdz-term: theme '${ZSH_THEME:-}' not found in $THANGDZ/themes" >&2
fi
