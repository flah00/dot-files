unset DYLD_LIBRARY_PATH
unset MANPATH

if [[ -d /opt/local/bin ]]; then
  alias screen=/opt/local/bin/screen
  alias vim=/opt/local/bin/vim
  alias vimdiff=/opt/local/bin/vimdiff
fi
alias vi=vim
alias vimex='vim --servername VIM -s ~/.vim/scripts/vimex.vim $*'
alias top="top -o cpu -O rsize"

[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f `brew --prefix 2>/dev/null`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.adaptly ]] && . ~/.adaptly
