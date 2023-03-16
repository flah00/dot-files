alias bi='beet import'
alias bim='beet import -m'
alias biC='beet import -C'
alias vim=nvim.appimage
alias vi=vim
alias vimdiff='vim -d'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias p5p='aws --profile=p5p'
alias er301='cd er-301; ./testing/linux/emu/emu.elf; cd -'

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

alias govim='vim -u ~/.vimrc.go'

type aws &>/dev/null && complete -C /usr/bin/aws_completer p5p

case `uname -s` in
Linux)
  alias ls='ls --color=auto'
  ;;
Darwin|*[Bb][Ss][Dd]*)
  alias top="top -o cpu -O rsize"
  ;;
esac
# vim:ft=sh:
