# vim {{{
if [[ -n $NVIM ]]; then
  export PS1="» "
  if [ -x $HOME/.local/bin/nvr ]; then
    alias vim=$HOME/.local/bin/nvr
  else
    alias vim='echo no nesting'
  fi
else
  alias vim=nvim
  GIT_PROMPT_THEME=Solarized
  GIT_PROMPT_ONLY_IN_REPO=1
  source ~/.bash-git-prompt/gitprompt.sh
fi
alias cal='ncal -b -S'
alias vi=vim
alias vimdiff='vim -d'
# }}}

alias bash=/bin/bash
alias okta='flatpak run com.okta.developer.CLI'
# grep {{{
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
# }}}

alias nexus-user='op read op://DevOps/Nexus\ Prod\ Admin/username'
alias nexus-pass='op read op://DevOps/Nexus\ Prod\ Admin/password'
alias tf='terraform'
alias tfda='terraform-docs asciidoc . >README.adoc'
alias tg='terragrunt'
alias tgc='tg run -- console'
alias tgab='tg apply tfplan.binary'
alias tfdm='terraform-docs markdown table . >README.md'
alias tgpht='env ENABLE_HELM_MANIFEST=true terragrunt plan'
alias tgphf='env -u ENABLE_HELM_MANIFEST terragrunt plan'
alias p5p='aws --profile=p5p'
alias am='aws --profile=master'
alias an='aws --profile=droit-network'
alias ap='aws --profile=prod'
alias as='aws --profile=sandbox'
alias at='aws --profile=stage'
alias ai='aws --profile=prod-shared-infra'
alias ascb='aws --profile=droit-scg-hosted-lv-dl'
acomp_path=$(which aws_completer)
if [[ $acomp_path ]]; then
  complete -C $acomp_path aws
  complete -C $acomp_path am
  complete -C $acomp_path an
  complete -C $acomp_path ap
  complete -C $acomp_path as
  complete -C $acomp_path at
  complete -C $acomp_path ai
  complete -C $acomp_path ascb
  complete -C $acomp_path p5p
  complete -C $acomp_path aa
fi

alias h=helm
complete -o default -o nospace -F __start_helm h
complete -o default -o nospace -F __start_helm ha
alias k=kubectl
complete -o default -F __start_kubectl k
complete -o default -F __start_kubectl ka
alias kc=kubectx
alias kn=kubens

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

case $(uname -s) in
Linux)
  alias ls='ls --color=auto'
  ;;
Darwin | *[Bb][Ss][Dd]*)
  alias top="top -o cpu -O rsize"
  ;;
esac

function setupjdk8 {
  export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
  export LEIN_JAVA_CMD=${JAVA_HOME}/bin/java
  sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
}

function setupjdk11 {
  export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
  export LEIN_JAVA_CMD=${JAVA_HOME}/bin/java
  sudo update-java-alternatives -s java-1.11.0-openjdk-amd64
}

[[ $(type -t direnv) ]] && eval "$(direnv hook bash)"

pk() {
  declare -a dirs
  dirs=($(pwd | awk -F/ '{$1=""; print $0}'))

  #/home/philip.champon/devel/tf-infrastructure/sandbox-727224488023/sandbox/us-east-1/eks-cluster
  >&2 echo ${dirs[@]}
  region=${dirs[6]}
  name=${dirs[5]}
  acct_name=${dirs[4]/-*/}
  acct_id=${dirs[4]/*-/}
  >&2 echo "an:$acct_name ai:$acct_id n:$name r:$region"
  (
    set -x
    kubectl --context "arn:aws:eks:$region:$acct_id:cluster/$name" $@
  )
}

_file_in_dir_path() {
  local file=$1
  local dir="." file_path
  while true; do
    if [[ -f $dir/$file ]]; then
      file_path=$(realpath "$dir/$file")
      break
    elif [[ $(realpath "$dir") = / ]]; then
      return 1
    fi
    dir+=/..
  done
  echo "$file_path"
}

_yaml_value() {
  local file_name=$1 yaml_key=$2 yaml_path value
  yaml_path=$(_file_in_dir_path "$file_name")
  value="$(yq -r "$yaml_key" "$yaml_path" 2>/dev/null)"
  if [[ ! $value ]]; then
    >&2 echo "Could not find $yaml_key in ${yaml_path}"
    return 1
  fi
  echo "$value"
}

_kubectx() {
  local aws_region aws_account_id droit_env
  aws_account_id="$(_yaml_value account.yaml .aws_account_id)"
  [[ $? -eq 0 ]] || return 1

  aws_region="$(_yaml_value region.yaml .aws_region)"
  [[ ! $aws_region ]] && aws_region=$(aws --profile "$aws_profile" configure get region)
  if [[ ! $aws_region ]]; then
    aws_region="us-east-1"
    >&2 echo "Region is undefined, defaulting to $aws_region"
  elif [[ $aws_region = "global" ]]; then
    >&2 echo "Region in path is 'global', will use us-east-1."
    aws_region="us-east-1"
  fi

  droit_env="$(_yaml_value environment.yaml .environment)"
  >&2 echo "$aws_account_id $aws_region $droit_env"
  ctx="$(printf "arn:aws:eks:%s:%s:cluster/%s" "$aws_region" "$aws_account_id" "$droit_env")"
  echo "$ctx"
}

ha() {
  local ctx=$(_kubectx)
  helm --kube-context "$ctx" "$@"
}
# arn:aws:eks:ap-southeast-1:381492021368:cluster/client-integration
# arn:aws:eks:REGION:ACCT_ID:cluster/ENV
ka() {
  local ctx=$(_kubectx)
  local ns=${PWD##*/}
  (
    set -x
    kubectl --context "$ctx" --namespace "$ns" "$@"
  )
}

aa() {
  local region_yaml aws_profile aws_region
  aws_profile="$(_yaml_value account.yaml .aws_profile)"
  [[ $? -eq 0 ]] || return 1

  aws_region="$(_yaml_value region.yaml .aws_region)"
  [[ ! $aws_region ]] && aws_region=$(aws --profile "$aws_profile" configure get region)
  if [[ ! $aws_region ]]; then
    aws_region="us-east-1"
    >&2 echo "Region is undefined, defaulting to $aws_region"
  elif [[ $aws_region = "global" ]]; then
    >&2 echo "Region in path is 'global', will use us-east-1."
    aws_region="us-east-1"
  fi
  >&2 echo "$aws_profile $aws_region"
  aws --profile "$aws_profile" --region "$aws_region" "$@"
}

# vim:ft=sh:
