alias vi=vim
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias east='aws --profile=prod-east'
alias west='aws --profile=prod-west'
alias zoo='aws --profile=zoo'
alias p5p='aws --profile=p5p'
alias prod_maint='aws_maintenance.rb -r us-east-1 -p prod-east'
alias stag_maint='aws_maintenance.rb -r us-west-2 -p prod-west'
alias zoo_maint='aws_maintenance.rb -r us-east-1 -p zoo'
alias kprod='kubectl --context=k9s-production'
alias hprod='helm --kube-context=k9s-production'
alias kprodold='kubectl --context=production'
alias kstag='kubectl --context=staging'
alias hstag='helm --kube-context=staging'
alias kzoo='kubectl --context=zoo'
alias hzoo='helm --kube-context=zoo'

type aws &>/dev/null && complete -C /usr/local/bin/aws_completer aws
type aws &>/dev/null && complete -C /usr/local/bin/aws_completer east
type aws &>/dev/null && complete -C /usr/local/bin/aws_completer west
type aws &>/dev/null && complete -C /usr/local/bin/aws_completer zoo
type aws &>/dev/null && complete -C /usr/local/bin/aws_completer p5p

case ${UNAMES:-`uname -s`} in
Linux)
  alias ls='ls --color=auto'
  ;;
Darwin|*[Bb][Ss][Dd]*)
  alias top="top -o cpu -O rsize"
  ;;
esac
# vim:ft=sh:
