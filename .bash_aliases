# vim {{{
if [[ -n $NVIM ]]; then
  export PS1="» "
  if [ -x $HOME/.local/bin/nvr ]; then
    alias vim=$HOME/.local/bin/nvr
  else
    alias vim='echo no nesting'
  fi
else
  alias vim='nvim -u ~/.SpaceVim/vimrc'
  GIT_PROMPT_THEME=Solarized
  GIT_PROMPT_ONLY_IN_REPO=1
  source ~/.bash-git-prompt/gitprompt.sh
fi
alias vi=vim
alias vimdiff='vim -d'
# }}}

# grep {{{
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
# }}}

alias p5p='aws --profile=p5p'
alias am='aws --profile=master'
alias an='aws --profile=nonprod'
alias ap='aws --profile=prod'
alias as='aws --profile=sandbox'
alias at='aws --profile=stage'
acomp_path=$(which aws_completer)
if [[ $acomp_path ]]; then
  complete -C $acomp_path aws
  complete -C $acomp_path am
  complete -C $acomp_path an
  complete -C $acomp_path ap
  complete -C $acomp_path as
  complete -C $acomp_path at
  complete -C $acomp_path p5p
fi

alias k=kubectl
complete -o default -F __start_kubectl k

alias er301='cd er-301; ./testing/linux/emu/emu.elf; cd -'

alias bi='beet import'
alias bim='beet import -m'
alias biC='beet import -C'
alias qlplaypause='quodlibet --play-pause'
alias qlvolume='quodlibet --volume '
alias qlnow='quodlibet --print-playing'
alias qlnext='quodlibet --next'
alias qlrating='quodlibet --set-rating'
alias qlscan='quodlibet --refresh'
alias qlquery-avg='quodlibet --query="&(grouping = &(!nopod),genre=&( !podcast, !spoken), #(rating >= 0.4))"'
alias qlquery-better='quodlibet --query="&(grouping = &(!nopod),genre=&( !podcast, !spoken), #(rating >= 0.6))"'
alias qlquery-recent='quodlibet --query="#(added<=2 weeks)"'
alias qlunqueue='quodlibet --unqueue="$(quodlibet --print-query-text)"'
alias qlenqueue='quodlibet --enqueue="$(quodlibet --print-query-text)"'

function qlbeetnow() {
  if [[ $# -gt 0 ]]; then
    full="$*"
    set -x
  else
    full=$(quodlibet --print-playing)
  fi
  title=$(echo "$full" | sed 's/.* [0-9]\+\/[0-9]\+ - //')
  # no track info available, use less precise split
  if [[ $title = $full ]]; then
    title=$(echo "$full" | sed 's/.* - //')
  fi
  artist=$(echo "$full" | sed 's/ -.*//')
  beet ls -f '$artist - $album - $track - $title - $year - $genre - $comments - $grouping - $length $bitrate' \
    title:"$title" artist:"$artist"
  set +x
}

case `uname -s` in
Linux)
  alias ls='ls --color=auto'
  ;;
Darwin|*[Bb][Ss][Dd]*)
  alias top="top -o cpu -O rsize"
  ;;
esac
# vim:ft=sh:
