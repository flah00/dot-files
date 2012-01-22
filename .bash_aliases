alias mongo='rlwrap mongo'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias vimex='vim --servername VIM -s ~/.vim/scripts/vimex.vim $*'

case ${UNAMES:-} in
Linux)
	alias ls='ls --color=auto'
  ;;
Darwin|*[Bb][Ss][Dd]*)
  alias top="top -o cpu -O rsize"
  ;;
esac
# vim:ft=sh:
