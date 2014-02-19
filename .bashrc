unset DYLD_LIBRARY_PATH
unset MANPATH

test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f `brew --prefix 2>/dev/null`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.bashrc_adaptly ]] && . ~/.bashrc_adaptly

