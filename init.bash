# thangdz-term loader (bash) — load order: lib → aliases (shared with zsh) → theme
if [[ -z "${THANGDZ:-}" || ! -f "$THANGDZ/init.bash" ]]; then
  echo "thangdz-term: \$THANGDZ does not point to the repo directory" >&2
  return 1
fi

shopt -s nullglob

for _f in "$THANGDZ"/lib/*.bash; do
  source "$_f"
done

# Shared aliases (plain alias definitions, safe in both shells)
for _f in "$THANGDZ"/aliases/*.zsh; do
  source "$_f"
done

shopt -u nullglob
unset _f

if [[ -n "${BASH_THEME:-}" && -f "$THANGDZ/themes/$BASH_THEME.bash" ]]; then
  source "$THANGDZ/themes/$BASH_THEME.bash"
else
  echo "thangdz-term: theme '${BASH_THEME:-}' not found in $THANGDZ/themes" >&2
fi
