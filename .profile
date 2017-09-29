#export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export ENV=~/.bashrc
[ -e $ENV ] && . $ENV || :
[ -d ~/bin ] && export PATH=$PATH:~/bin || :
#[ $TERM = "xterm" -o $TERM = "xterm-color" ] && export TERM="xterm-256color"
export LANG='en_US.UTF-8'
export CDPATH=".:~/devel"
export HTML_TIDY=~/.tidyrc
export HISTCONTROL="erasedups:ignorespace"
export CLICOLOR=1
#export LSCOLORS="Dxfxcxdxbxegedabagacad"
#export PATH=$PATH:/usr/local/share/npm/bin
#export NODE_PATH=/usr/local/lib/node
export JS_CMD=node
export EDITOR=vim
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=svn
