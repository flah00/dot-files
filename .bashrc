eval `dircolors ~/devel/dot-files/dircolors-solarized/dircolors.ansi-universal`

[ -d ~/.rbenv ] && PATH="$HOME/.rbenv/bin:$PATH"
test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

[[ $(type -t terraform &>/dev/null) ]] && complete -C /usr/bin/terraform terraform

export NVM_DIR="$HOME/.nvm"
export NVM_COLORS=cgYmM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

