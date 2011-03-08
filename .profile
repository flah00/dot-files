#export PATH=/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH
export ENV=~/.bashrc
if [ -e $ENV ]; then
	. $ENV
fi
if [ -d ~/bin ]; then
	export PATH=$PATH:~/bin
fi

[ $TERM = "xterm" -o $TERM = "xterm-color" ] && export TERM="xterm-256color"
export UNAMES=$(uname -s)
export CDPATH=".:~/devel/adaptly"
export HTML_TIDY=~/.tidyrc
export SCREENDIR=$HOME/.screens
export HISTCONTROL="erasedups:ignorespace"
export CLICOLOR=1
export LSCOLORS="Dxfxcxdxbxegedabagacad"
export EDITOR=vim

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=svn

NODE_PATH=$(type node | awk '{print$3}')
if [[ -f $NODE_PATH ]]; then
  p=$(dirname $NODE_PATH)
  export PATH=$PATH:${p%/*}/share/npm/bin
  export NODE_PATH=${p%/*}/lib/node
fi

