# Show the ThangDZ logo on every new shell (set SHOW_LOGO=0 in zshrc to disable)
if [[ "${SHOW_LOGO:-1}" == 1 && -o interactive && -t 1 ]]; then
  print -Pn "%F{cyan}"
  cat "$MY_ZSH/lib/logo.txt"
  print -Pn "%f"
fi
