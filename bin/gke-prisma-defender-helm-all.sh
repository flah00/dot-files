#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
shopt -s nocasematch
project=$GOOGLE_CLOUD_PROJECT
tmp=/tmp/$$.gc.gke.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-p PROJECT] [-m PATTERN] [-o PATH] [-i BOOL] [-S OS] [-y]"
  echo -e "\t-a ACTION  download, install, upgrade, status, pods, uninstall, uninstall_caas2" 
  echo -e "\t-p PROJECT Google project (default $project)"
  echo -e "\t-m PATTERN Only apply the ACTION to cluster names matching PATTERN"
  echo -e "\t-o PATH    Write results to PATH as CSV for owner, status, or pods"
  echo -e "\t-i BOOL    Enable Prisma CRI true or false (default automatic)"
  echo -e "\t-S OS      OS of the node workers: linux or windows (default $worker_os)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}
function skip() { clusters_skip+=($1); }
function error() { clusters_error+=($1); }

worker_os=linux
while getopts a:p:m:o:i:S:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    p) gcloud config set project $OPTARG ;;
    m) match=$OPTARG ;;
    o) csv=$OPTARG ;;
    i) 
      case $OPTARG in
        t|true|y|yes|1) cri=true ;;
        f|false|n|no|0) cri=false ;;
        *) usage 2 ;;
      esac
      ;;
    S)
      case $OPTARG in
        l*) worker_os=linux ;;
        w*) worker_os=windows ;;
        *) usage 2 ;;
      esac
    y) yes=-y ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
set -x; gcloud container clusters list --format=json | jq -r '.[] |= [.name, .status]'>$tmp; set +x

if [[ $match ]]; then
  clusters=($(jq -r '.[][0] | select(contains("'"$match"'"))' $tmp))
else
  clusters=($(jq -r '.[][0]' $tmp))
fi
echo Found ${#clusters[@]}
if [[ ! -r ~philip.champon/.prisma && ! -r ~/.prisma && ! $yes ]]; then
  echo WARN .prisma file not found, you will be required to input prisma key and secret ${#clusters[@]} times
  echo WARN Alternatively, you can generate a key and secret, as a cloud-provisioning-admin in prisma
  echo WARN https://app2.prismacloud.io/settings/access_control/access_keys and copy the csv to ~/.prisma
  echo -n "Continue [Y/n] "
  read accept
  [[ $accept != "" && ! $accept =~ ^y(es)? ]] && exit 2
fi
[[ $action = owner && $csv ]] && echo "Cluster,Id,Prisma Name,Owner" > $csv
[[ $action = status && $csv ]] && echo "Cluster,Id,Prisma Name,Prisma Chart Version" > $csv
[[ $action = pods && $csv ]] && echo "Cluster,Id,Prisma Name,Prisma Pod Name,Status" > $csv

declare -i successes=0 total=0
declare -a clusters_skip clusters_error
TEE=$(mktemp /tmp/${0##*/}XXXX)
for cluster in ${clusters[@]}; do
  total+=1
  state=$(jq -r '.[] | select(.[0]=="'$cluster'") | .[1]' $tmp)
  cluster_short=$(echo $cluster | sed 's/-cluster$//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short begin ===

  if [[ $action = debug ]]; then
    if [[ $state != Running ]]; then
      echo "WARN Skipping cluster $cluster state '$state'"
      skip $cluster
      echo -e "\n=== $cluster id $id end ===\n\n"
      continue
    fi
    if ! kubectl config use-context $cluster || ! gke-get-credentials.sh -i $cluster; then
      echo WARN Skipping cluster $cluster, context not defined
      skip $cluster
      echo -e "\n=== $cluster id $id end ===\n\n"
      continue
    fi
    nodes=($(kubectl --request-timeout=3s get node -o jsonpath={..name} -l kubernetes.io/os=linux))
    for node in ${nodes[@]}; do
      echo $(tput setaf 1)To access the worker node:$(tput sgr0) $(tput rev)exec chroot /host$(tput sgr0)
      echo + kubectl --request-timeout=3s debug node/$node --image=busybox -ti 1>&2
      kubectl --request-timeout=3s debug node/$node --image=busybox -ti
      [[ $? -eq 0 ]] && successes+=1 || error $cluster
      #kubectl --request-timeout=3s delete pod -l app=debug
    done

  elif [[ $action = owner ]]; then
    set -x; owner=$(jq -r '.[] | select(.cn=="'$cluster'") | if(.owner) then .owner else .Owner end' $tmp); set +x
    echo Owner $owner
    [[ $csv ]] && echo "\"$cluster\",$id,\"$cluster_short\",\"$owner\"" >> $csv
    [[ $owner = null || ! $owner ]] && error $cluster || successes+=1

  elif [[ $state = RUNNING ]]; then
    args="-a $action -c $cluster -n $cluster_short -S $worker_os -C google"
    [[ $yes ]] && args+=" $yes"
    [[ $cri ]] && args+=" -i $cri"
    echo + prisma-defender-helm.sh $args
    prisma-defender-helm.sh $args | tee $TEE
    [[ $(echo "${PIPESTATUS[@]}" | tr -s ' ' + | bc) -eq 0 ]] && successes+=1 || error $cluster
    if [[ $csv && $action = status ]]; then
      ver=$(grep twistlock $TEE | awk '{print$9}')
      echo "\"$cluster\",$id,\"$cluster_short\",\"$ver\"" >> $csv
    elif [[ $csv && $action = pods ]]; then
      ifs="$IFS"
      IFS="
"
      for p in $(grep twistlock $TEE | awk '{printf "\"%s\",\"%s\"\n", $1, $3}'); do 
        echo "\"$cluster\",$id,\"$cluster_short\",$p" >> $csv
      done
      IFS="$ifs"
    fi

  else
    echo "WARN Skipping cluster $cluster state '$state'"
    skip $cluster
    echo -e "\n=== $cluster short $cluster_short end ===\n\n"
    continue
  fi
  echo -e "\n=== $cluster short $cluster_short end ===\n\n"
done

echo Errors: ${#clusters_error[@]}
[[ ${#clusters_error[@]} -gt 0 ]] && echo -e "\t${clusters_error[@]}"
echo Successes: $successes
echo Skipped: ${#clusters_skip[@]}
[[ ${#clusters_skip[@]} -gt 0 ]] && echo -e "\t${clusters_skip[@]}"
echo Total: $total
exit ${#clusters_error[@]}

