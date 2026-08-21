# Only load on macOS
[[ "$OSTYPE" != darwin* ]] && return

alias showfiles='defaults write com.apple.finder AppleShowAllFiles true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles false && killall Finder'
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
