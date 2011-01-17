unset DYLD_LIBRARY_PATH
export EDITOR=/opt/local/bin/vim
export PS1='\h:\w \u\$ '
alias vim=/opt/local/bin/vim
alias vi=vim
alias vimex='vim --servername VIM -s ~/.vim/scripts/vimex.vim $*'
alias top="top -o cpu -O rsize"
unset MANPATH

[ -d /usr/local/etc/bash_completion.d/ ] && . /usr/local/etc/bash_completion.d/*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.
