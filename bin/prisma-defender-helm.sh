#!/usr/bin/env bash
# Multiple clusters in RG

# Usage description in getopts section
#
# NOTE: This script does not support taints and labels!
#
# If you do not specify a cluster context the current context will be used!
#
# You will be prompted for a prisma access key id and secret. You can obtain
# this from the UI. The id and secret can also be read from
# ~philip.champon/.prisma.
#
# Install or Upgrade a prisma defender helm chart
# ./isd_helm.sh -a install -n some-cluster-name
# ./isd-helm.sh -a upgrade -n some-cluster-name
# 1. Optionally verify the kubectl context exists; Make it the current context
# 2. Verify cluster name is not too long (<= 20 char)
# 3. Obtain token from prisma api; Verify token was successfully generated
# 4. Fetch helm chart from prisma; Verify the chart was successfully fetched
# 5. Install/upgrade the helm chart
#
# Uninstall the caas2 daemonset
# ./isd_helm.sh -a uninstall_caas2 -c some-context-name
# 1. Delete kubernetes objects from twistlock namespace
trap 'exit 1' TERM INT

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
  echo ${0##*/} -a ACTION -n NAME [-c CONTEXT] [-i BOOL] [-y] [-d] [-C CLOUD] [-u URL] [-p PATH] [-P PORT]
  echo -e "\t-a ACTION  download, install, upgrade, status, pods, uninstall, uninstall_caas2"
  echo -e "\t-n NAME    The prisma name of the cluster (<= 20 char)"
  echo -e "\t-c CONTEXT kubectl context helm uses (default is current context)"
  echo -e "\t-i BOOL    Enable CRI true or false (default automatic)"
  echo -e "\t-C CLOUD   Cloud platform azure, google, aws (default $cloud)"
  echo -e "\t-u URL     The prisma console URL (default $console)"
  echo -e "\t-p PATH    The Prisma console path prefix (default $console_path)"
  echo -e "\t-P PORT    The Prisma console port (default $console_port)"
  echo -e "\t-d         Do not download the helm chart, use the existing file ./twistlock-defender-helm.tar.gz"
  echo -e "\t-D         Download the chart, do not run helm"
  echo -e "\t-y         Yes to all prompts"
  exit
}

# POV instance: CAAS2 us-west1.cloud.twistlock.com/us-4-161028402
# production instance: APP2
console=us-east1.cloud.twistlock.com
console_port=443
console_path=/us-2-158262739
if [[ -e ~/.azure && -e ~/.aws ]] || [[ -e ~/.azure && $(type gcloud &>/dev/null) ]] || [[ -e ~/.aws && $(type gcloud &>/dev/null) ]]; then
  :
elif [[ -e ~/.azure ]]; then
  cloud=azure
elif [[ -e ~/.aws ]]; then
  cloud=aws
elif [[ $(type gcloud &>/dev/null) ]]; then
  cloud=google
fi
while getopts 'a:n:c:C:u:p:P:i:hydD' arg; do
  case $arg in
    D) helm_action=download ;;
    a) helm_action=$OPTARG ;;
    n) cluster_name=$OPTARG ;;
    c) cluster_context=$OPTARG ;;
    i)
      case $OPTARG in
        t|true|y|yes|1) cri=true ;;
        f|false|n|no|0) cri=false ;;
      esac
      ;;
    C) cloud=$OPTARG ;;
    y) confirmed=true ;;
    d) downloaded=true ;;
    u) console=$OPTARG ;;
    p) console_path=$OPTARG ;;
    P) console_port=$OPTARG ;;
    *) usage ;;
  esac
done

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
  uninstall)
    cur_version=$(helm ls -n twistlock --filter ^twistlock-defender-ds | awk '{print$9}')
    if [[ ! $cur_version ]]; then
      echo ERROR helm chart twistlock-defender-ds is not installed 1>&2
      exit 2
    fi
    echo UNINSTALL helm chart twistlock-defender-ds version $cur_version from cluster $(kubectl config get-context)
    confirm $confirmed
    set -x; exec helm uninstall twistlock-defender-ds --namespace twistlock
    ;;

  status)
    set -x; exec helm ls -n twistlock 
    ;;

  pods)
    set -x; exec kubectl --request-timeout=3s -n twistlock get pods
    ;;

  uninstall_caas2)
    cur_version=$(helm ls -n twistlock --filter ^twistlock-defender-ds | awk '{print$9}')
    if [[ $cur_version ]]; then
      echo ERROR helm was used to install defender, use action uninstall 1>&2
      exit 2
    fi
    echo Delete proof of concept prisma defender from cluster $(kubectl config current-context)
    confirm $confirmed
    declare -i ex=0
    set -x
    kubectl --request-timeout=3s delete clusterrolebinding twistlock-view-binding
    ex+=$?
    kubectl --request-timeout=3s delete clusterrole twistlock-view
    ex+=$?
    kubectl --request-timeout=3s delete ns twistlock
    ex+=$?
    set +x
    if [[ $ex -ne 0 ]]; then
      echo Errors encountered, not waiting for pods to terminate 2>&1
    else
      echo -n Waiting for pods to terminate
      while [[ $(kubectl -n twistlock get po|wc -l) -gt 1 ]]; do 
        sleep 1
        echo -n .
      done
      echo
    fi
    exit $ex
    ;;

  install|upgrade|download)
    if [[ ! $cluster_name ]]; then
      echo "The -n flag is required" 1>&2
      exit 2
    elif [[ ${cluster_name:0:20} != $cluster_name ]]; then
      echo ERROR Cluster Name \'$cluster_name\' is more than 20 characters 1>&2
      exit 1
    fi
    if [[ $downloaded = true ]]; then
      if [[ ! -f ./twistlock-defender-helm.tar.gz ]]; then
        echo "ERROR You must download twistlock-defender-helm.tar.gz or do not specify -d flag" 1>&2
        exit 1
      fi

    else
      # Format is either CSV or line 1 access key and line 2 secret, ie
      # Access Key ID,123-456-789
      # Secret Key,Somestring
      # OR
      # 123-456-789
      # Somestring
      if [[ -r ~philip.champon/.prisma ]]; then
        access_key_id=$(head -1 ~philip.champon/.prisma | sed 's/[^,]*,//')
        secret_key=$(tail -1 ~philip.champon/.prisma | sed 's/[^,]*,//')

      elif [[ -r ~/.prisma ]]; then
        access_key_id=$(head -1 ~/.prisma | sed 's/[^,]*,//')
        secret_key=$(tail -1 ~/.prisma | sed 's/[^,]*,//')

      else
        echo The prisma access key and secret are required to ${helm_action} cluster ${cluster_name}
        echo -n 'Access Key ID: '
        read access_key_id
        echo -n 'Secret Key: '
        read secret_key
      fi

      # obtain token, 30m lifetime
      echo Fetching token...
      token=$(curl -k \
        --silent \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"username":"'$access_key_id'", "password":"'$secret_key'"}' \
        https://$console$console_path/api/v1/authenticate)
      [[ $? -ne 0 ]] && echo ERROR curl auth failed && exit 3

      if [[ $token =~ ^\{\"err ]]; then
        echo -e "ERROR echo $token\n" 1>&2
        exit 1
      fi
      # strip json, ie {"token":" and "}
      token=${token##*token\":\"}
      token=${token%%\"\}}

      if [[ ! $cri ]]; then
        cri=false
        # only linux is supported, so let's not consult runtime of potential windows workers
        # don't forget, there could be multiple node pools running different OS/container runtimes 
        echo + kubectl --request-timeout=3s get node -l kubernetes.io/os=linux -o jsonpath='{..containerRuntimeVersion}' 1>&2
        runtimes=($(kubectl --request-timeout=3s get node -l kubernetes.io/os=linux -o jsonpath='{..containerRuntimeVersion}'))
        [[ $? -ne 0 ]] && echo ERROR failed to determine CRI, re-run the previous command and set -i flag to false if output is docker: or true otherwise && exit 3
        for runtime in ${runtimes[@]}; do
          # if the container runtime isn't docker we set CRI to true
          [[ ! $runtime =~ ^docker: ]] && cri=true && break
        done
        echo Setting CRI to $cri
      fi
      data='{ "orchestration": "kubernetes", "consoleAddr": "'$console:$console_port'", "namespace": "twistlock", "cluster": "'$cluster_name'", "cri": '$cri', "uniqueHostname": true, "serviceAccounts": true }'
      echo Submitting request: $data
      echo Fetching helm chart...
      curl -k \
        --silent \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $token" \
        -X POST \
        -O \
        -d "$data" \
        https://$console$console_path/api/v1/defenders/helm/twistlock-defender-helm.tar.gz

      [[ $? -ne 0 ]] && echo ERROR curl helm download failed && exit 3
      # If we get back non-binary data something went wrong...
      if head -1 twistlock-defender-helm.tar.gz | grep -qi '"err"'; then
        echo -e "ERROR $(cat twistlock-defender-helm.tar.gz)\n" 1>&2
        rm twistlock-defender-helm.tar.gz
        exit 1
      fi
    fi

    if ! helm lint ./twistlock-defender-helm.tar.gz &> /tmp/out; then
      echo ERROR $(cat /tmp/out) 1>&2
      rm -f /tmp/out
      exit 1
    else
      rm -f /tmp/out
    fi

    chart_version=$(helm show chart ./twistlock-defender-helm.tar.gz | grep ^version:)
    cur_version=$(helm ls -n twistlock --filter ^twistlock-defender-ds | awk '{print$9}')
    # chart-name-0.1.2 -> 0.1.2
    cur_version=${cur_version##*-}
    [[ $cur_version ]] && echo -e "\tcurrent version: $cur_version" || echo -e "\tcurrent version: NOT INSTALLED"
    echo -e "\tnew $chart_version"
    echo CLUSTER CONTEXT $(kubectl config current-context)
    echo CLUSTER NAME ${cluster_name}
    [[ $helm_action = download ]] && echo "Downloaded twistlock-defender-helm.tar.gz, exiting" && exit 0
    confirm $confirmed
    echo + helm $helm_action twistlock-defender-ds ./twistlock-defender-helm.tar.gz \
      --namespace twistlock \
      --create-namespace \
      --atomic \
      --timeout=2m
    helm $helm_action twistlock-defender-ds ./twistlock-defender-helm.tar.gz \
      --namespace twistlock \
      --create-namespace \
      --atomic \
      --timeout=2m
    ex=$?
    rm -f twistlock-defender-helm.tar.gz
    exit $ex
    ;;

  *)
    echo "ERROR Helm action '$helm_action' undefined" 1>&2
    exit 2
    ;;
esac

