#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given profile
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
  echo "${0##*/} -a ACTION [-p PROFILE] [-r REGION] [-y]"
  echo -e "\t-a ACTION  owner, download, install, upgrade, uninstall, uninstall_caas2"
  echo -e "\t-p PROFILE AWS profile (default $profile)"
  echo -e "\t-r REGION  AWS region (default $region)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}

while getopts a:p:r:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    p) profile=$OPTARG ;;
    r) region=$OPTARG ;;
    y) yes=-y ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
describe_all

clusters=($(jq -r '.[].name' $tmp))
declare -i skipped=0 errors=0 successes=0 total=0
for cluster in ${clusters[@]}; do
  total+=1
  cluster_short=$(echo $cluster | sed 's/-cluster$//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short begin ===
  if ! kubectl config use-context $cluster &>/dev/null; then
    echo + eks-get-credentials.sh -p $profile -r $region -i $cluster 
    eks-get-credentials.sh -p $profile -r $region -i $cluster || continue
  fi
  echo + prisma-defender-helm.sh $yes -a $action -c $cluster -n $cluster_short -C aws
  prisma-defender-helm.sh $yes -a $action -c $cluster -n $cluster_short
  [[ $? -eq 0 ]] && successes+=1 || errors+=1
  echo -e "\n=== $cluster id $id end ===\n\n"
done

echo Errors: $errors
echo Successes: $successes
#echo Skipped: $skipped
echo Total: $total
