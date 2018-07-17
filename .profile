export PATH=/usr/local/bin:/usr/local/sbin:$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH
[ -d /usr/local/opt/scala@2.11/bin ] && export PATH="/usr/local/opt/scala@2.11/bin:$PATH"
export ENV=~/.bashrc
[ -e $ENV ] && . $ENV
[ -d /opt/k8s ] && export PATH=/opt/k8s/bin:$PATH
[ -d ~/bin ] && export PATH=$PATH:~/bin
shopt -s globstar

[ $TERM = "xterm" -o $TERM = "xterm-color" ] && export TERM="xterm-256color"
export GOPATH=$HOME/go
export JAVA_HOME=/opt/jdk/default
export PAGER=less
export LANG='en_US.UTF-8'
#export LC_ALL=C
export CDPATH=".:~/devel"
export HTML_TIDY=~/.tidyrc
export HISTCONTROL="erasedups:ignorespace"
export HISTSIZE=10000
export HISTFILESIZE=10000
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

export PATH=$PATH:$GOPATH/bin

[ -d $JAVA_HOME/bin ] && export PATH=$JAVA_HOME/bin:$PATH
