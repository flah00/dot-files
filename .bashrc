eval `dircolors ~/devel/dircolors-solarized/dircolors.ansi-universal`

[ -d ~/.rbenv ] && PATH="$HOME/.rbenv/bin:$PATH"
test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

complete -C /usr/bin/terraform terraform

export NVM_DIR="$HOME/.nvm"
export NVM_COLORS=cgYmM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

PATH="/home/flah00/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/flah00/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/flah00/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/flah00/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/flah00/perl5"; export PERL_MM_OPT;

