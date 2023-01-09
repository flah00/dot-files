#!/usr/bin/env bash

# Usage description in getopts section
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

# POV instance: CAAS2 us-west1.cloud.twistlock.com/us-4-161028402
# production instance: APP2
console=us-east1.cloud.twistlock.com/us-2-158262739
while getopts 'a:n:c:u:hyd' arg; do
  case $arg in
    a) helm_action=$OPTARG ;;
    n) cluster_name=$OPTARG ;;
    c) cluster_context=$OPTARG ;;
    u) console=$OPTARG ;;
    y) confirmed=true ;;
    d) downloaded=true ;;
    *)
      echo ${0##*/} -a HELM_ACTION -n CLUSTER_NAME [-c CLUSTER_CONTEXT] [-u URL] [-y] [-d]
      echo -e "\t-a HELM_ACTION install, upgrade, or uninstall_caas2"
      echo -e "\t-n CLUSTER_NAME The prisma name of the cluster (<= 20 char)"
      echo -e "\t-c CLUSTER_CONTEXT kubectl context helm uses (default is current context)"
      echo -e "\t-u URL The prisma console URL (default $console)"
      echo -e "\t-y Do not confirm config options before running helm"
      echo -e "\t-d Do not download the helm chart, use the existing file ./twistlock-defender-helm.tar.gz"
      exit
      ;;
  esac
done

if [[ $cluster_context ]]; then
  if ! kubectl config use-context $cluster_context &>/dev/null; then
    echo WARN kubectl context $cluster_context does not exist 1>&2
    echo aks-get-credentials.sh -i $cluster_context 1>&2
    # AZEUKS-I-5429-IDVS-Cluster1 -> 5429
    id=$(echo $cluster_context | sed -E 's/[^0-9]*([0-9]{4,})[^0-9]*/\1/')
    aks-get-credentials.sh -i $id || exit 3
  fi
fi

# special action, which does not use helm...
if [[ $helm_action = uninstall_caas2 ]]; then
  echo Delete proof of concept prisma defender from cluster $(kubectl config current-context)
  confirm $confirmed
  ex=0
  set -x
  kubectl delete clusterrolebinding twistlock-view-binding
  ex+=$?
  kubectl delete clusterrole twistlock-view
  ex+=$?
  kubectl -n twistlock delete secrets twistlock-secrets
  ex+=$?
  kubectl -n twistlock delete sa twistlock-service
  ex+=$?
  kubectl -n twistlock delete service defender
  ex+=$?
  kubectl -n twistlock delete ds twistlock-defender-ds 
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
fi

if [[ ! $helm_action || ! $cluster_name ]]; then
  echo "The -a and -n flags are required" 1>&2
  exit 2
fi

if [[ ${cluster_name:0:20} != $cluster_name ]]; then
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
    https://$console/api/v1/authenticate)

  if [[ $token =~ ^\{\"err ]]; then
    echo -e "ERROR echo $token\n" 1>&2
    exit 1
  fi
  # strip json, ie {"token":" and "}
  token=${token##*token\":\"}
  token=${token%%\"\}}

  echo Fetching helm chart...
  curl -k \
    --silent \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $token" \
    -X POST \
    -O \
    -d '{ "orchestration": "container", "consoleAddr": "'$console'", "namespace": "twistlock", "cluster": "'$cluster_name'", "cri": true, "uniqueHostname": true }' \
    https://$console/api/v1/defenders/helm/twistlock-defender-helm.tar.gz

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
echo -e DEPLOYING ./twistlock-defender-helm.tar.gz
[[ $cur_version ]] && echo -e "\tcurrent version: $cur_version" || echo -e "\tcurrent version: NOT INSTALLED"
echo -e "\tnew $chart_version"
echo CLUSTER CONTEXT $(kubectl config current-context)
echo CLUSTER NAME ${cluster_name}
confirm $confirmed
if [[ $helm_action = uninstall ]]; then
  set -x
  exec helm uninstall twistlock-defender-ds --namespace twistlock
else
  set -x
  exec helm $helm_action twistlock-defender-ds ./twistlock-defender-helm.tar.gz \
    --namespace twistlock \
    --create-namespace \
    --atomic \
    --timeout=10m
fi

