#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
sub=b1e119d0-b7fa-451d-af39-0611d33b30dc
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-s SUB]"
  echo -e "\t-a ACTION install, upgrade, uninstall, uninstall_caas2"
  echo -e "\t-s SUB    Azure subscription (default $sub)"
  echo -e "\t-y        Yes to all prompts"
  exit 1
}

while getopts a:s:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    s) sub=$OPTARG ;;
    y) yes=-y ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
stat=$(stat -c '%Z' ~/.azure/az.sess)
now=$(date +%s)
## session file written to more than 12h ago
[[ $((now-stat)) -gt $((now-43200)) ]] && echo YOU MUST LOGIN && az login
set -x
az account set --subscription $sub
az aks list --query '[].{cn:name, rg:resourceGroup}' >$tmp 
set +x
clusters=($(jq -r '.[].cn' $tmp))

for cluster in ${clusters[@]}; do
  # AZEUKS-I-5429-IDVS-Cluster1 -> 5429
  id=$(echo $cluster | sed -E 's/[^0-9]*([0-9]{4,})[^0-9]*/\1/')
  cluster_short=$(echo $cluster | sed 's/-cluster$//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short id $id begin ===
  if ! kubectl config get-contexts | grep -q $cluster; then
    set -x; aks-get-credentials.sh -i $id; set +x
    if [[ $? -ne 0 ]]; then
      echo Skipping $cluster, failed to fetch kubectl credentials
      continue
    fi
  fi
  set -x; prisma-defender-helm.sh $yes -a $action -c $cluster -n $cluster_short; set +x
  echo
  echo === $cluster id $id end ===
done
