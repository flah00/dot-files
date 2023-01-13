#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
sub=b1e119d0-b7fa-451d-af39-0611d33b30dc
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-s SUB] [-m PATTERN] [-o PATH] [-y]"
  echo -e "\t-a ACTION  owner, download, install, upgrade, status, pods, uninstall, uninstall_caas2" 
  echo -e "\t-m PATTERN Only apply the ACTION to cluster names matching PATTERN"
  echo -e "\t-s SUB     Azure subscription (default $sub)"
  echo -e "\t-o PATH    Write results to PATH as CSV for owner, status, or pods"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}
function skip() { skipped+=1; clusters_skip+=($1); }
function error() { errors+=1; clusters_error+=($1); }

while getopts a:s:m:o:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    s) sub=$OPTARG ;;
    m) match=$OPTARG ;;
    o) csv=$OPTARG ;;
    y) yes=-y ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
[[ $(uname -s) = Darwin ]] && stat=$(stat -f '%m' ~/.azure/az.sess) || stat=$(stat -c '%Z' ~/.azure/az.sess)
now=$(date +%s)
## session file written to more than 12h ago
[[ $((now-stat)) -gt $((now-43200)) ]] && echo YOU MUST LOGIN && az login
set -x
az account set --subscription $sub
az aks list --query '[].{cn:name, rg:resourceGroup, state:powerState.code, Owner:tags.Owner, owner:tags.owner }' >$tmp 
set +x
if [[ $match ]]; then
  clusters=($(jq -r '.[].cn | select(contains("'"$match"'"))' $tmp))
else
  clusters=($(jq -r '.[].cn' $tmp))
fi
echo Found ${#clusters[@]}
[[ $action = owner && $csv ]] && echo "Cluster,Id,Prisma Name,Owner" > $csv
[[ $action = status && $csv ]] && echo "Cluster,Id,Prisma Name,Prisma Chart Version" > $csv
[[ $action = pods && $csv ]] && echo "Cluster,Id,Prisma Name,Prisma Pod Name,Status" > $csv

declare -i skipped=0 errors=0 successes=0 total=0
delcare -a clusters_skip clusters_error
TEE=$(mktemp /tmp/${0##*/}XXXX)
for cluster in ${clusters[@]}; do
  total+=1
  state=$(jq -r '.[] | select(.cn=="'$cluster'") | .state' $tmp)
  # AZEUKS-I-5429-IDVS-Cluster1 -> 5429
  id=$(echo $cluster | sed -E 's/[^0-9]*([0-9]{4,})[^0-9].*/\1/')
  cluster_short=$(echo $cluster | sed 's/-cluster.*//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short id $id begin ===
  if [[ $action = debug ]]; then
    if [[ $state != Running ]]; then
      echo "WARN Skipping cluster $cluster state '$state'"
      skip $cluster
      echo -e "\n=== $cluster id $id end ===\n\n"
      continue
    fi
    kubectl config use-context $cluster-admin || aks-get-credentials.sh -i $id || continue
    nodes=($(kubectl --request-timeout=3s get node -o jsonpath={..name} -l kubernetes.io/os=linux))
    for node in ${nodes[@]}; do
      echo $(tput setaf 1)To access the worker node:$(tput sgr0) $(tput rev)exec chroot /host$(tput sgr0)
      echo + kubectl --request-timeout=3s debug node/$node --image=busybox -ti 1>&2
      kubectl --request-timeout=3s debug node/$node --image=busybox -ti
      [[ $? -eq 0 ]] && successes+=1 || error $cluster
    done

  elif [[ $action = owner ]]; then
    set -x; owner=$(jq -r '.[] | select(.cn=="'$cluster'") | if(.owner) then .owner else .Owner end' $tmp); set +x
    echo Owner $owner
    [[ $csv ]] && echo "\"$cluster\",$id,\"$cluster_short\",\"$owner\"" >> $csv
    [[ $owner = null || ! $owner ]] && error $cluster || successes+=1

  elif [[ $state = Running ]]; then
    echo + prisma-defender-helm.sh $yes -a $action -c $cluster-admin -n $cluster_short -C azure
    prisma-defender-helm.sh $yes -a $action -c $cluster-admin -n $cluster_short -C azure | tee $TEE
    [[ $? -eq 0 ]] && successes+=1 || error $cluster
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
    echo "WARN Skipping $cluster, state is '$state'"
    [[ $csv ]] && echo "\"$cluster\",$id,\"$cluster_short\"," >> $csv
    skip $cluster
  fi

  echo -e "\n=== $cluster id $id end ===\n\n"
done

echo Errors: $errors
[[ ${#clusters_error[@]} -gt 0 ]] && echo -e "\t${clusters_error[@]}"
echo Successes: $successes
echo Skipped: $skipped
[[ ${#clusters_skip[@]} -gt 0 ]] && echo -e "\t${clusters_skip[@]}"
echo Total: $total
exit $errors
