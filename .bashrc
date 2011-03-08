unset DYLD_LIBRARY_PATH
unset MANPATH

[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f `brew --prefix 2>/dev/null`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
