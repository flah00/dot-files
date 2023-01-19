#!/usr/bin/env bash
# Install fluent/fluent-bit in the siem namespace release soc
# Only permit this daemonset pod to run on kubernetes.io/os=linux
# 1. helm repo add
# 2. helm repo update
# 3. confirm action
# 4. helm install/upgrade/uninstall
#

trap 'exit 1' TERM INT

# a base64 gzip file of the soc.yaml values file
function create_values() {
  file=$(mktemp /tmp/${0##*/}-XXXXXX)
  echo $file
  cat <<EOT | base64 -d | gzip -d > $file
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
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
  echo ${0##*/} -a ACTION [-n NAME] [-c CONTEXT] [-v VERSION] [-r REV] [-d LOC] [-y] [-C CLOUD]
  echo -e "\t-a ACTION  download, install, upgrade, status, history, rollback, pods, uninstall"
  echo -e "\t-c CONTEXT kubectl context helm uses (default is current context)"
  echo -e "\t-n NAME    The name of the cluster; becomes cluster_name= metadata; required to install/upgrade"
  echo -e "\t-v VERSION A semantic version string (default $fluent_bit_version)\n\t\thttps://github.com/Masterminds/semver#hyphen-range-comparisons"
  echo -e "\t-C CLOUD   Cloud platform azure, google, aws (default $cloud)"
  echo -e "\t-r REV     Helm history revision number, required when rolling back"
  echo -e "\t-d LOC     Specify the helm chart location, can be helm or local file (default $fluent_bit)"
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
while getopts 'a:c:n:C:v:d:r:Dyh' arg; do
  case $arg in
    D) helm_action=download ;;
    a) helm_action=$OPTARG ;;
    c) cluster_context=$OPTARG ;;
    n) cluster_name=$OPTARG ;;
    C) cloud=$OPTARG ;;
    v) fluent_bit_version="$OPTARG" ;;
    r) helm_revision=$OPTARG ;;
    d) fluent_bit=$OPTARG ;;
    y) confirmed=true ;;
    *) usage ;;
  esac
done

# make sure helm repo is configured ...
if ! helm repo ls | grep -q ^fluent[[:space:]]; then
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
    exec kubectl --request-timeout=3s --namespace $helm_namespace get pods
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
    sed "s/REPLACE_THIS/$cluster_name/" < $orig_values > $new_values
    orig_sum=$(openssl md5 $orig_values | awk '{print$2}')
    new_sum=$(openssl md5 $new_values | awk '{print$2}')
    if [[ $orig_sum = $new_sum ]]; then
      echo ERROR Unable to set cluster name in new values.yaml $new_values 1>&2
      exit 3
    fi
    chart_version=$(helm show chart ./twistlock-defender-helm.tar.gz | grep ^version:)
    cur_version=$(helm ls -n twistlock --filter ^twistlock-defender-ds | awk '{print$9}')
    # chart-name-0.1.2 -> 0.1.2
    cur_version=${cur_version##*-}
    [[ $cur_version ]] && echo -e "\tcurrent version: $cur_version" || echo -e "\tcurrent version: NOT INSTALLED"
    confirm $confirmed
    echo -e "\tnew $chart_version"
    echo CLUSTER CONTEXT $(kubectl config current-context)
    echo CLUSTER NAME ${cluster_name}
    set -x
    # 2023-01-19: linux only, we don't have a windows solution just yet
    # NOTE: must escape the .io period, lest it turn into a new key
    exec helm upgrade $helm_release $fluent_bit \
      --set "nodeSelector.kubernetes\\.io/os=linux" \
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

