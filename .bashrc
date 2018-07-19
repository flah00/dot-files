GIT_PROMPT_THEME=Solarized
GIT_PROMPT_ONLY_IN_REPO=1
source "$HOME/.bash-git-prompt/gitprompt.sh"

test `which rbenv` && eval "$(rbenv init -)"
[[ -f ~/.completion/all ]] && . ~/.completion/all
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -f ~/.bashrc_adaptly ]] && . ~/.bashrc_adaptly
[[ -f ~/devel/dockerfiles/scripts/aliases.sh ]] && . ~/devel/dockerfiles/scripts/aliases.sh

#eval $(east ecr get-login)
