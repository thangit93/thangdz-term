# Show the ThangDZ logo on every new shell (set SHOW_LOGO=0 in bashrc/zshrc to disable)
if [[ "${SHOW_LOGO:-1}" == 1 && -t 1 ]]; then
  printf '\e[36m'
  cat "$THANGDZ/lib/logo.txt"
  printf '\e[0m'
fi
