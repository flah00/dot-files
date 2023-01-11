#!/bin/bash
project=tfo-us-dev-va-macaron
tmp=/tmp/$$.gc.gke.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "Get kubectl configs for a cluster or all known clusters in the project"
  echo "${0##*/} {-a | -i ID | -c CLUSTER -z ZONE} [-p PROJECT]"
  echo -e "\t-a          configure all of the clusters"
  echo -e "\t-i ID       the cluster ID, ie 5524"
  echo -e "\t-c CLUSTER  the name of the cluster, ie AZEUKS-I-5458-OCW-DEV-Cluster"
  echo -e "\t-z ZONE     the name of the google zone, ie us-central1-a"
  echo -e "\t-p PROJECT  the cloud project name (default $project)"
  echo
  echo -e "\tFetch all kubectl configs found in the project"
  echo -e "\t${0##*/} -a"
  echo -e "\tSpecify an id, it will configure cluster name and resource group for you"
  echo -e "\t${0##*/} -i 5524"
  echo -e "\tSpecify a cluster name and resource group name"
  echo -e "\t${0##*/} -c AZEUDKS-I-5524-CACT-Cluster -r I-5524-CommandAndControlTower-RG"
  exit 1
}
while getopts i:c:r:p:ah arg; do
  case $arg in
    i) id=$OPTARG ;;
    c) cn=$OPTARG ;;
    r) zn=$OPTARG ;;
    p) project=$OPTARG ;;
    a) all=true ;;
    *) usage ;;
  esac
done

#if [[ $(gcloud config get project) != $project ]]; then
  #set -x; gcloud config set project $project; set +x
#fi

if [[ $all ]]; then 
  echo Preparing to fetch all kubectl configs for $sub
  set -x; gcloud container clusters list --format=json >$tmp ; set +x
  # select all of the cluster names and zones
  clusters=($(jq -r '.[].name' $tmp))
  zones=($(jq -r '.[].zone' $tmp))
  if [[ ${#clusters[@]} -ne ${#zones[@]} || ${#clusters[@]} -lt 1 ]]; then
    echo Differing number of clusters and zones or 0 clusters
    echo Found "clusters '${clusters[@]}'"
    echo Found "zones '${zones[@]}'"
    exit 1
  fi

elif [[ $id ]]; then
  echo Searching for id $id in $sub
  set -x; gcloud container clusters list --format=json >$tmp ; set +x
  # only select the cluster and zones that matches the id
  clusters=($(jq -r '.[] | select(.name |contains("'$id'")) | .name' $tmp))
  zones=($(jq -r '.[] | select(.name |contains("'$id'")) | .zone' $tmp))
  if [[ ${#clusters[@]} -ne ${#zones[@]} || ! ${clusters[0]} || ! ${zones[0]} ]]; then
    echo Missing one or both from az aks list
    echo Found "cluster '${clusters[@]}' ${#clusters[@]}"
    echo Found "zones '${zones[@]}' ${#zones[@]}"
    exit 1
  fi

elif [[ $cn && $zn ]]; then
  echo Configuring cluster $cn with zones $zn in $project
  clusters=($cn)
  zones=($zn)
  if [[ ${#clusters[@]} -ne ${#zones[@]} || ! ${clusters[0]} || ! ${zones[0]} ]]; then
    echo Missing one or both from az aks list
    echo Found "cluster '${clusters[@]}' ${#clusters[@]}"
    echo Found "zone '${zones[@]}' ${#zones[@]}"
    exit 1
  fi

else
  echo must declare -a or -i or -c AND -z
  usage
fi

let "n=${#clusters[@]}-1"
for i in $(seq 0 $n); do
  set -x
  gcloud container clusters get-credentials ${clusters[$i]} --zone ${zones[$i]} 
  set +x
done
