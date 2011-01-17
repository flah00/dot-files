[ -z $PS1 ] && exit 

if [ `uname -s` = "Darwin" ]; then
	unset DYLD_LIBRARY_PATH
	export EDITOR=/opt/local/bin/vim
	alias vim=/opt/local/bin/vim
	alias vi=vim
	alias top="top -o cpu -O rsize"
	unset MANPATH
	[ -d /usr/local/etc/bash_completion.d/ ] && . /usr/local/etc/bash_completion.d/*
else
	[[ -f $HOME/.bash_aliases ]] && . $HOME/.bash_aliases
fi

alias vimex='vim --servername VIM -s ~/.vim/scripts/vimex.vim $*'
export PS1='\h:\w \u\$ '

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.
