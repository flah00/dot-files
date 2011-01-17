#export PATH=/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH
export ENV=~/.bashrc
if [ -e $ENV ]; then
	. $ENV
fi
if [ -d ~/bin ]; then
	export PATH=$PATH:~/bin
fi

##
# Your previous /Users/flah/.profile file was backed up as /Users/flah/.profile.macports-saved_2009-06-27_at_12:03:53
##

# MacPorts Installer addition on 2009-06-27_at_12:03:53: adding an appropriate DISPLAY variable for use with MacPorts.
#export DISPLAY=:0
# Finished adapting your DISPLAY environment variable for use with MacPorts.


##
# Your previous /Users/flah/.profile file was backed up as /Users/flah/.profile.macports-saved_2010-03-13_at_12:38:29
##

# MacPorts Installer addition on 2010-03-13_at_12:38:29: adding an appropriate PATH variable for use with MacPorts.
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

export HTML_TIDY=~/.tidyrc
export SCREENDIR=$HOME/.screens
export HISTCONTROL="ignorespace:ersasedups"
export HISTCONTROL="erasedups:ignorespace"
export SVN_URL="https://subversion.assembla.com/svn/retwip"
export APPLICATION_ENV=development
export CLICOLOR=1
export LSCOLORS="Dxfxcxdxbxegedabagacad"
