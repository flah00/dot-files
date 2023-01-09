#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# ARG1: action: install, upgrade, uninstall, uninstall_caas2
# ARG2: azure subscription
action=${1:?Missing action}
sub=${2:-b1e119d0-b7fa-451d-af39-0611d33b30dc}
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
set -x
stat=$(stat -c '%Z' ~/.azure/az.sess)
now=$(date +%s)
## session file written to more than 12h ago
[[ $((now-stat)) -gt $((now-43200)) ]] && echo YOU MUST LOGIN && az login
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
  set -x; prisma-defender-helm.sh -a $action -n $cluster_short; set +x
  echo
  echo === $cluster id $id end ===
done
