#!/bin/bash
sub=b1e119d0-b7fa-451d-af39-0611d33b30dc
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "Get kubectl configs for a cluster or all known clusters in the subscription"
  echo "${0##*/} {-a | -i ID | -c CLUSTER -r RESOURCE} [-s SUB]"
  echo -e "\t-a          configure all of the clusters"
  echo -e "\t-i ID       the cluster ID, ie 5524"
  echo -e "\t-c CLUSTER  the name of the cluster, ie AZEUKS-I-5458-OCW-DEV-Cluster"
  echo -e "\t-r RESOURCE the name of the az resource group, ie I-5524-CommandAndControlTower-RG"
  echo -e "\t-s SUB      the az subscription id (default $sub)"
  echo
  echo -e "\tFetch all kubectl configs found in the subscription"
  echo -e "\t${0##*/} -a"
  echo -e "\tSpecify an id, it will configure cluster name and resource group for you"
  echo -e "\t${0##*/} -i 5524"
  echo -e "\tSpecify a cluster name and resource group name"
  echo -e "\t${0##*/} -c AZEUDKS-I-5524-CACT-Cluster -r I-5524-CommandAndControlTower-RG"
  exit 1
}
while getopts i:c:r:s:ah arg; do
  case $arg in
    i) id=$OPTARG ;;
    c) cn=$OPTARG ;;
    r) rg=$OPTARG ;;
    s) sub=$OPTARG ;;
    a) all=true ;;
    *) usage ;;
  esac
done

stat=$(stat -c '%Z' ~/.azure/az.sess)
now=$(date +%s)
## session file written to more than 12h ago
[[ $((now-stat)) -gt $((now-43200)) ]] && echo YOU MUST LOGIN && az login
set -x; az account set --subscription $sub; set +x

if [[ $all ]]; then 
  echo Preparing to fetch all kubectl configs for $sub
  set -x; az aks list --query '[].{cn:name, rg:resourceGroup}' >$tmp ; set +x
  # select all of the cluster names and resource groups
  clusters=($(jq -r '.[].cn' $tmp))
  resources=($(jq -r '.[].rg' $tmp))
  if [[ ${#clusters[@]} -ne ${#resources[@]} || ${#clusters[@]} -lt 1 ]]; then
    echo Differing number of clusters and resource groups or 0 clusters
    echo Found "clusters '${clusters[@]}'"
    echo Found "resources '${resources[@]}'"
    exit 1
  fi

elif [[ $id ]]; then
  echo Searching for id $id in $sub
  set -x; az aks list --query '[].{cn:name, rg:resourceGroup}' >$tmp ; set +x
  # only select the cluster and resource group that matches the id
  clusters=($(jq -r '.[].cn | select(contains("'$id'"))' $tmp))
  resources=($(jq -r '.[].rg | select(contains("'$id'"))' $tmp))
  if [[ ${#clusters[@]} -ne ${#resources[@]} || ! ${clusters[0]} || ! ${resources[0]} ]]; then
    echo Missing one or both from az aks list
    echo Found "cluster '${clusters[@]}' ${#clusters[@]}"
    echo Found "resource '${resources[@]}' ${#resources[@]}"
    exit 1
  fi

elif [[ $cn && $rg ]]; then
  echo Configuring cluster $cn with resrouce group $rg in $sub
  clusters=($cn)
  resources=($rg)
  if [[ ${#clusters[@]} -ne ${#resources[@]} || ! ${clusters[0]} || ! ${resources[0]} ]]; then
    echo Missing one or both from az aks list
    echo Found "cluster '${clusters[@]}' ${#clusters[@]}"
    echo Found "resource '${resources[@]}' ${#resources[@]}"
    exit 1
  fi

else
  echo must declare -a or -i or -c AND -r
  usage
fi

let "n=${#clusters[@]}-1"
for i in $(seq 0 $n); do
  echo az aks get-credentials --resource-group ${resources[$i]} --name ${clusters[$i]} --admin
  az aks get-credentials --resource-group ${resources[$i]} --name ${clusters[$i]} --admin
done
