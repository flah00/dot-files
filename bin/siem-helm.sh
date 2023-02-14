#!/usr/bin/env bash
# Install fluent/fluent-bit in the siem namespace release soc
# 1. helm repo add
# 2. helm repo update
# 3. confirm action
# 4. helm install/upgrade/uninstall
trap 'exit 1' TERM INT
shopt -s expand_aliases
alias kubectl='kubectl --request-timeout=3s'

# a base64 gzip file of the soc.yaml values file
function create_values() {
  file=$(mktemp /tmp/${0##*/}-XXXXXX)
  echo $file
  cat <<EOT | base64 -d | gzip -d > $file
H4sICKAy0GMCA3ZhbHVlcy55YW1sAMVVTW/iSBC98ytKyi1KzMdAluFGEmeCBgLCnpFGo5XV2GXTwu72drczYbU/fqttxzhAVspcNhxiV71+XR+vyhcwXazhdrWECJ95iBr6f/ScwXDs9If0v3MB09X01D/qO/2byu8u3HOAgfNp5PQ/DwkxExFnZzluxpaCZyzBCQENSyYwcHrO+DrCTZF0FGpZKDox6QCkPOOmfAII82IC/V4vK98yzKTa09HRzYKTReFfBeo32NERtD8YEzSUIuaJhV3A8hmV4hEXCZgtQq4oLLWHZ5YSF2wwZIVGkDHEPEXQe20wg00Rx6h0SfC09F1Yo4jIAHFa6O0VpDKZ4zOmwEREdxvFQ72SygAXNbOzZ1kKcqNligaJSKOyRZrAP2XAPz13/X125/5Zvtm/e0Y5CFjGcWN6sLdBv3mfyySo7uUilo15xRSx6+DBZpBXL46twXlEWGgjs+As8NH3V4FHoaKCpXhrnnOqjYCeU/7e+srkB71By4wsNdvgbovhrk11QZcrEoaTM7OF7jNTXapmN04317Wne4rVexGCkCpj6akztFfoIqMmxqfeDQt3dIFDCglKqZG+Fh3b2QvYGpPrSbcbyVA71FoUZsONw2U3Y6JgaTfnOaZcYJeLvDBWD9XDaxc/TtE1jFc5/Jw9rb75h/4/sQyh8VZda1eI+kReQS3rXjpkOKTqvoRpEWHwPj7QnNK/vDrvjDBmRWre9SfyXRdn2XVRSuuyiScjLm5TdiqJAdVmh+oKQsUbkM8S2BUbdA7nFhTibRGTzqouUZuaFEHgr3JCNU0xM5BSVyGXXHPDaWgiZlgDXiOLggdFEicNRmBUgS2inAKiOeMkD4xKyoPzthz7YMFeAo//jfBpsGudvJckQQMkrPyVwW6VMqor4DHYnCFFkVAb8CVEjDQcUTZ03o7nwVwKGmg6pe2EVIr6DUlVSyt6X1VtwGvxt1KbVvEPRfNJgnU4HwqG6mCsKDIZ8XhPp2tDs/EeZnPfXR+F1qBrDTATbuEQ1jSK7KqnPUhUgbAn1u5qPr1zA/9x5nX+g9mqSwlavvqI/UR2KkFqRdLeUl8R88rW2ilfx9412RLqulNt1DdHWt56In+njLIw9aqpn5r6Lb/5b1or6ta2d0FWZnjUW/tqv9PBbNXYcruwR/3h4aSkeIsobwwVcxDbrWtAxeFoOBgeezP2ou2kDHrD8bFP05dKcbMPdrinZbaeLdcz/8cJPwtpWbyivB/efPkleJjezeZnwDYTm3YFDh6Xnv80XbjHMJbnBxQEd8vF4hiSKxnyqEZAsJrdn6SGWtMHpIYsXM+bfnE7H23Fkdj+r1ZUmZ4ZiTPJ2iQ6/wJcZ1XhQQoAAA==
EOT
}
function confirm() {
  confirmed=$1
  if [[ ! $confirmed ]]; then
    # default is to accept and run helm
    echo -n 'Accept [Y/n] '
    read accept
    [[ $accept != "" && ! $accept =~ ^y(es)? ]] && exit 2
  fi
}
function usage() {
  echo "Manage the helm chart $fluent_bit in namespace $helm_namespace release $helm_release"
  echo ${0##*/} -a ACTION [-n NAME] [-c CONTEXT] [-v VERSION] [-r REV] [-d LOC] [-R REGION] [-S OS] [-y] [-C CLOUD]
  echo -e "\t-a ACTION  download, install, upgrade, status, history, rollback, pods, uninstall"
  echo -e "\t-c CONTEXT kubectl context helm uses (default is current context)"
  echo -e "\t-n NAME    The name of the cluster; becomes cluster_name= metadata; required to install/upgrade"
  echo -e "\t-v VERSION A semantic version string (default $fluent_bit_version)\n\t\thttps://github.com/Masterminds/semver#hyphen-range-comparisons"
  echo -e "\t-C CLOUD   Cloud platform azure, google, aws (default $cloud)"
  echo -e "\t-r REV     Helm history revision number, required when rolling back"
  echo -e "\t-d LOC     Specify the helm chart location, can be helm or local file (default $fluent_bit)"
  echo -e "\t-R REGION  The account region, ie AMR, APA, EMEA, India (default $account_region)"
  echo -e "\t-S OS      OS of the node workers: linux or windows (default $worker_os)"
  echo -e "\t-D         Download the chart, do not run helm"
  echo -e "\t-y         Yes to all prompts"
  exit ${1:-0}
}

if [[ -e ~/.azure && -e ~/.aws ]] || [[ -e ~/.azure && $(type gcloud &>/dev/null) ]] || [[ -e ~/.aws && $(type gcloud &>/dev/null) ]]; then
  :
elif [[ -e ~/.azure ]]; then
  cloud=azure
elif [[ -e ~/.aws ]]; then
  cloud=aws
elif [[ $(type gcloud &>/dev/null) ]]; then
  cloud=google
fi
# default is latest
fluent_bit_version=">0.0.0"
fluent_bit=fluent/fluent-bit
helm_release=soc
helm_namespace=siem
account_region=$(az account show --query 'name')
worker_os=linux
while getopts 'a:c:n:C:v:d:r:R:S:Dyh' arg; do
  case $arg in
    D) helm_action=download ;;
    a) helm_action=$OPTARG ;;
    c) cluster_context=$OPTARG ;;
    n) cluster_name=$OPTARG ;;
    C) cloud=$OPTARG ;;
    v) fluent_bit_version="$OPTARG" ;;
    r) helm_revision=$OPTARG ;;
    R) account_region=$OPTARG ;;
    d) fluent_bit=$OPTARG ;;
    y) confirmed=true ;;
    S)
      case $OPTARG in
        l*) worker_os=linux ;;
        w*) worker_os=windows ;;
        *) usage 2 ;;
      esac
      ;;
    *) usage ;;
  esac
done

# make sure helm repo is configured ...
if ! helm repo ls | grep -q "^fluent[[:space:]]"; then
  echo + helm repo add fluent https://fluent.github.io/helm-charts 1>&2
  helm repo add fluent https://fluent.github.io/helm-charts
fi
# and that the version we want is there?
fluent_bit_repo_version=$(helm search repo fluent-bit | grep ^$fluent_bit | awk '{print$2}')
if [[ $fluent_bit_version != ">0.0.0" && $fluent_bit_repo_version != $fluent_bit_version ]]; then
  echo + helm repo update fluent 1>&2
  helm repo update fluent
fi

# make sure the kubectl context is available
if [[ $cluster_context ]]; then
  if ! kubectl config use-context $cluster_context &>/dev/null; then
    echo WARN kubectl context $cluster_context does not exist 1>&2
    case $cloud in
      azure)
        echo + aks-get-credentials.sh -i $cluster_context 1>&2
        aks-get-credentials.sh -i $cluster_context || exit 3
        ;;
      google)
        echo + gke-get-credentials.sh -i $cluster_context 1>&2
        gke-get-credentials.sh -i $cluster_context || exit 3
        ;;
      aws)
        echo + eks-get-credentials.sh -i $cluster_context 1>&2
        eks-get-credentials.sh -i $cluster_context || exit 3
        ;;
      *)
        echo ERROR $cloud not configured 1>&2
        exit 2
        ;;
    esac
  fi
fi

if [[ ! $helm_action ]]; then
  echo "The -a flag is required" 1>&2
  exit 2
fi

[[ ! $account_region ]] && account_region=$(az account show --query 'name')
case $account_region in
  *-US-*|*-us-*|*-CA-*|*-ca-*|*-BR-*|*-br-*|*-LATAM-*|*-latam-*|*AMR*|*amr*)
    echo Setting account region to AMR
    syslog_ip=170.248.140.2
    ;;
  *as*|*AS*|*apa*|*APA*)
    echo Setting account region to APA
    syslog_ip=170.251.160.2
    ;;
  *-EU-*|*-eu-*|*emea*|*EMEA*)
    echo Setting account region to EMEA
    syslog_ip=170.252.35.194
    ;;
  ind*|Ind*)
    echo Setting account region to India
    syslog_ip=170.251.68.2
    ;;
  *)
    echo "ERROR Cannot determine account name ('$account_region'), use flag to specify EMEA, AMR, APA, or India" 1>&2
    exit 2
    ;;
esac

case $helm_action in
  download)
    set -x
    exec helm pull $fluent_bit --version="$fluent_bit_version"
    ;;
  un*)
    cur_version=$(helm ls -n $helm_namespace --filter ^$helm_release | awk '{print$9}')
    if [[ ! $cur_version ]]; then
      echo ERROR helm chart $fluent_bit release $helm_release is not installed 1>&2
      exit 2
    fi
    echo $(tput setaf 1)UNINSTALL helm chart $fluent_bit version $cur_version from cluster $(kubectl config current-context)$(tput sgr0)
    confirm $confirmed
    set -x
    exec helm uninstall $helm_release --namespace $helm_namespace --timeout=2m
    ;;
  status)
    set -x
    exec helm ls --namespace $helm_namespace --filter ^$helm_release
    ;;
  pods)
    set -x
    exec kubectl --namespace $helm_namespace get pods
    ;;
  history)
    set -x
    exec helm history --namespace $helm_namespace $helm_release
    ;;
  rollback)
    [[ ! $helm_revision ]] && echo ERROR rollback requires a revision 1>&2 && usage 2
    cur_rev=$(helm ls -n $helm_namespace --filter ^$helm_release | awk '{print$3}')
    if [[ ! $cur_rev ]]; then
      echo ERROR helm chart $fluent_bit release $helm_release is not installed 1>&2
      exit 2
    elif [[ $cur_rev = $helm_revision ]]; then
      echo ERROR helm chart $fluent_bit release $helm_release is already at revision $helm_revision 1>&2
      exit 2
    fi
    echo $(tput setaf 1)ROLLBACK helm chart $fluent_bit current revision $cur_version rollback to $helm_revision
    echo          cluster $(kubectl config current-context)$(tput sgr0)
    confirm $confirmed
    set -x
    exec helm rollback $helm_release $helm_revision --namespace $helm_namespace --recreate-pods --cleanup-on-fail --timeout=5m
    ;;
  in*|up*)
    [[ ! $cluster_name ]] && echo ERROR cluster name is required && usage 2
    new_values=$(mktemp /tmp/${0##*/}-XXXXX)
    orig_values=$(create_values)
    sed -e "s/REPLACE_THIS/$cluster_name/" -e "s/BPO_IP/$syslog_ip/" < $orig_values > $new_values
    orig_sum=$(openssl md5 $orig_values | awk '{print$2}')
    new_sum=$(openssl md5 $new_values | awk '{print$2}')
    if [[ $orig_sum = $new_sum ]]; then
      echo ERROR Unable to set cluster name in new values.yaml $new_values 1>&2
      exit 3
    fi
    echo CLUSTER CONTEXT $(kubectl config current-context)
    echo CLUSTER NAME ${cluster_name}
    echo Node OS $worker_os Syslog IP $syslog_ip
    chart_version=$(helm search repo fluent-bit --version="$fluent_bit_version" | grep $fluent_bit | awk '{print$2}')
    cur_version=$(helm ls -n siem --filter ^soc | awk '{print$9}')
    # chart-name-0.1.2 -> 0.1.2
    cur_version=${cur_version##*-}
    [[ $cur_version ]] && echo -e "\tcurrent version: $cur_version" || echo -e "\tcurrent version: NOT INSTALLED"
    echo -e "\tnew $chart_version"
    confirm $confirmed
    set -x
    # 2023-01-19: linux only, we don't have a windows solution just yet
    # NOTE: must escape the .io period, lest it turn into a new key
    exec helm upgrade $helm_release $fluent_bit \
      --set "nodeSelector.kubernetes\\.io/os=$worker_os" \
      --version="$fluent_bit_version" \
      --values "$new_values" \
      --namespace $helm_namespace \
      --install \
      --create-namespace \
      --atomic \
      --timeout=2m
    ;;
  *)
    echo "ERROR Helm action '$helm_action' undefined" 1>&2
    exit 2
    ;;
esac

