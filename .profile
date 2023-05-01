#export PATH=/usr/local/bin:/usr/local/sbin:$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH
[ -d ~/.local/bin ] && PATH+=":$HOME/.local/bin"
[ -d ~/.tfenv/bin ] && PATH+=":$HOME/.tfenv/bin"
[ -d ~/.yarn/bin/ ] && PATH+=":$HOME/.yarn/bin/"
export ENV=~/.bashrc
# shellcheck source=/dev/null
[ -e $ENV ] && . $ENV
[ -d ~/bin ] && export PATH=$PATH:~/bin
shopt -s globstar

[ $TERM = "xterm" -o $TERM = "xterm-color" ] && export TERM="xterm-256color"
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PAGER=less
export LANG='en_US.UTF-8'
export LANGUAGE=$LANG
export LC_ALL=$LANG
export LC_COLLATE=C
export CDPATH=".:~/devel"
export HTML_TIDY=~/.tidyrc
export HISTCONTROL="erasedups:ignorespace"
export HISTSIZE=10000
export HISTFILESIZE=10000
export CLICOLOR=1
export JS_CMD=node
export EDITOR=vim
export BC_ENV_ARGS=~/.bc
export GPG_TTY=$(tty)

PATH=$PATH:$GOROOT/bin:$GOPATH/bin
