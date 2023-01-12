#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
sub=b1e119d0-b7fa-451d-af39-0611d33b30dc
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-s SUB] [-m PATTERN]"
  echo -e "\t-a ACTION  owners, download, install, upgrade, status, pods, uninstall, uninstall_caas2"
  echo -e "\t-m PATTERN Only apply the ACTION to cluster names matching PATTERN"
  echo -e "\t-s SUB     Azure subscription (default $sub)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}

while getopts a:s:m:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    s) sub=$OPTARG ;;
    m) match=$OPTARG ;;
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
az aks list --query '[].{cn:name, rg:resourceGroup, state:powerState.code, Owners:tags.Owners, owners:tags.owners }' >$tmp 
set +x
if [[ $match ]]; then
  clusters=($(jq -r '.[].cn | select(contains("'"$match"'"))' $tmp))
else
  clusters=($(jq -r '.[].cn' $tmp))
fi

declare -i skipped=0 errors=0 successes=0 total=0
for cluster in ${clusters[@]}; do
  total+=1
  state=$(jq -r '.[] | select(.cn=="'$cluster'") | .state' $tmp)
  # AZEUKS-I-5429-IDVS-Cluster1 -> 5429
  id=$(echo $cluster | sed -E 's/[^0-9]*([0-9]{4,})[^0-9].*/\1/')
  cluster_short=$(echo $cluster | sed 's/-cluster.*//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short id $id begin ===
  if [[ $action = owners ]]; then
    owners=$(jq -r '.[] | select(.cn=="'$cluster'") | .owners' $tmp)
    if [[ ! $owners ]]; then
      owners=$(jq -r '.[] | select(.cn=="'$cluster'") | .Owners' $tmp)
    fi
    echo Owners $owners
  elif [[ $state = Running ]]; then
    echo + prisma-defender-helm.sh $yes -a $action -c $cluster-admin -n $cluster_short
    prisma-defender-helm.sh $yes -a $action -c $cluster-admin -n $cluster_short -C azure
    [[ $? -eq 0 ]] && successes+=1 || errors+=1
  else
    echo "WARN Skipping $cluster, state is '$state'"
    skipped+=1
  fi
  echo -e "\n=== $cluster id $id end ===\n\n"
done

echo Errors: $errors
echo Successes: $successes
echo Skipped: $skipped
echo Total: $total
