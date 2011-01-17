#export PATH=/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH
export ENV=~/.bashrc
if [ -e $ENV ]; then
	. $ENV
fi
if [ -d ~/bin ]; then
	export PATH=$PATH:~/bin
fi

export HTML_TIDY=~/.tidyrc
export SCREENDIR=$HOME/.screens
export HISTCONTROL="erasedups:ignorespace"
export CLICOLOR=1
export LSCOLORS="Dxfxcxdxbxegedabagacad"
