if [ -f "$(brew --prefix bash-git-prompt)/share/gitprompt.sh" ]; then
  GIT_PROMPT_THEME=Solarized
  GIT_PROMPT_ONLY_IN_REPO=1
  source "$(brew --prefix bash-git-prompt)/share/gitprompt.sh"
fi

test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f `brew --prefix 2>/dev/null`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.bashrc_adaptly ]] && . ~/.bashrc_adaptly
[[ -f ~/devel/dockerfiles/scripts/aliases.sh ]] && . ~/devel/dockerfiles/scripts/aliases.sh
[[ -f ~/.bash_functions ]] && . ~/.bash_functions

#eval $(east ecr get-login)
