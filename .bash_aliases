alias mongo='rlwrap mongo'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias gemcd='cd $(dirname `gem show $1`)'
#alias bundlecd='cd $(bundle show $1)'
alias vi=vim
alias vimex='vim --servername VIM -s ~/.vim/scripts/vimex.vim $*'

case ${UNAMES:-} in
Linux)
	alias ls='ls --color=auto'
  ;;
Darwin|*[Bb][Ss][Dd]*)
  alias screen=/opt/local/bin/screen
  alias vim=/opt/local/bin/vim
  alias vimdiff=/opt/local/bin/vimdiff
  alias top="top -o cpu -O rsize"
  export EDITOR=$(alias vim | sed "s/.*\'\([^\']*\)\'/\1/")
  ;;
esac
# vim:ft=sh:
