#!/usr/bin/env bash
# 
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
  echo ${0##*/} -a ACTION -n NAME [-c CONTEXT] [-v VERSION] [-r REV] [-d LOC] [-y] [-C CLOUD]
  echo -e "\t-a ACTION  download, install, upgrade, status, history, rollback, pods, uninstall"
  echo -e "\t-n NAME    The prisma name of the cluster (<= 20 char)"
  echo -e "\t-c CONTEXT kubectl context helm uses (default is current context)"
  echo -e "\t-v VERSION A semantic version string (default $fluent_bit_version)\n\t\thttps://github.com/Masterminds/semver#hyphen-range-comparisons"
  echo -e "\t-C CLOUD   Cloud platform azure, google, aws (default $cloud)"
  echo -e "\t-r REV     Helm history revision number, required when rolling back"
  echo -e "\t-d LOC     Specify the helm chart location, can be helm or local file (default $fluent_bit)"
  echo -e "\t-D         Download the chart, do not run helm"
  echo -e "\t-y         Yes to all prompts"
  exit
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
while getopts 'a:n:c:C:v:d:r:Dyh' arg; do
  case $arg in
    D) helm_action=download ;;
    a) helm_action=$OPTARG ;;
    n) cluster_name=$OPTARG ;;
    c) cluster_context=$OPTARG ;;
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
    set -x
    exec helm uninstall $helm_release --namespace $helm_namespace --atomic --timeout=2m
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
    [[ ! $helm_revision ]] && echo ERROR rollback requires 1>&2 && exit 2
    set -x
    exec helm rollback $helm_release $helm_revision --namespace $helm_namespace --recreate-pods --cleanup-on-fail --timeout=5m
    ;;
  in*|up*)
    new_values=$(mktemp /tmp/${0##*/}-XXXXX)
    orig_values=$(create_values)
    sed "s/REPLACE_THIS/$cluster_name/" < $orig_values > $new_values
    orig_sum=$(openssl md5 $orig_values | awk '{print$2}')
    new_sum=$(openssl md5 $new_values | awk '{print$2}')
    if [[ $orig_sum != $new_sum ]]; then
      echo ERROR Unable to set cluster name in new values.yaml $new_values 1>&2
      exit 3
    fi
    set -x
    exec helm upgrade $helm_release $fluent_bit \
      --debug --dry-run \
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

