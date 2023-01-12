#!/bin/bash
profile=${AWS_DEFAULT_PROFILE:-default}
region=${AWS_DEFAULT_REGION:-us-east-1}
tmp=/tmp/$$.aws.eks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT

function describe_all() {
  TMPDIR=$(mktemp -d ${0##*})
  set -x
  clusters=($(aws --profile=$profile --region=$region eks list-clusters --query clusters --output=text))
  set +x
  for cluster in ${clusters[@]}; do
    set -x
    aws --profile=$profile --region=$region eks describe-cluster --query cluster --name $cluster --output=json >$TMPDIR/$cluster
    set +x
  done
  jq -s . $TMPDIR/* > $tmp
}

function usage() {
  echo "Get kubectl configs for a cluster or all known clusters in the account"
  echo "${0##*/} {-a | -i ID | -c CLUSTER -r REGION} [-p PROFILE]"
  echo -e "\t-a          configure all of the clusters"
  echo -e "\t-i PATTERN  the cluster ID, ie 5524"
  echo -e "\t-c CLUSTER  the name of the cluster, ie AZEUKS-I-5458-OCW-DEV-Cluster"
  echo -e "\t-r REGION   the AWS region (default: $region)"
  echo -e "\t-p PROFILE  the AWS profile (default: $profile)"
  echo
  echo -e "\tFetch all kubectl configs found in the profile"
  echo -e "\t${0##*/} -a"
  echo -e "\tSpecify an id, it will configure cluster name"
  echo -e "\t${0##*/} -i 5524"
  echo -e "\tSpecify a cluster name and resource group name"
  echo -e "\t${0##*/} -c AZEUDKS-I-5524-CACT-Cluster -r us-east-2"
  exit 1
}
while getopts i:c:r:p:ah arg; do
  case $arg in
    i) id=$OPTARG ;;
    c) cn=$OPTARG ;;
    r) rg=$OPTARG ;;
    p) project=$OPTARG ;;
    a) all=true ;;
    *) usage ;;
  esac
done

#if [[ $(gcloud config get project) != $project ]]; then
  #set -x; gcloud config set project $project; set +x
#fi

if [[ $all ]]; then 
  echo Preparing to fetch all kubectl configs for $profile
  describe_all

  # select all of the cluster names
  clusters=($(jq -r '.[].name' $tmp))
  if [[ ${#clusters[@]} -lt 1 ]]; then
    echo ERROR No clusters found
    exit 1
  fi

elif [[ $id ]]; then
  echo Searching for id $id in $profile
  describe_all
  # only select the cluster and zones that matches the id
  clusters=($(jq -r '.[] | select(.name |contains("'$id'")) | .name' $tmp))
  if [[ ! ${clusters[0]} ]]; then
    echo Cluster not found
    exit 1
  fi

elif [[ $cn ]]; then
  echo Configuring cluster $cn in region $rg in profile $profile
  clusters=($cn)
  if [[ ! ${clusters[0]} ]]; then
    echo Cluster not defined
    exit 1
  fi

else
  echo must declare -a or -i or -c AND -z
  usage
fi

#let "n=${#clusters[@]}-1"
#for i in $(seq 0 $n); do
for cluster in ${clusters[@]}; do
  set -x
  aws --profile=$profile --region=$region eks update-kubeconfig --name $cluster
  set +x
done

