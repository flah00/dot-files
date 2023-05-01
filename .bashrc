eval `dircolors ~/devel/dot-files/dircolors-solarized/dircolors.ansi-universal`

[ -d ~/.rbenv ] && PATH="$HOME/.rbenv/bin:$PATH"
test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/devel/dot-files/completion/all ]] && . ~/devel/dot-files/completion/all
[[ -f ~/devel/dot-files/.bash_functions ]] && . ~/devel/dot-files/.bash_functions 
[[ -f ~/devel/dot-files/.bash_aliases ]] && . ~/devel/dot-files/.bash_aliases 

[[ $(type -t terraform &>/dev/null) ]] && complete -C /usr/bin/terraform terraform

export NVM_DIR="$HOME/.nvm"
export NVM_COLORS=cgYmM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

