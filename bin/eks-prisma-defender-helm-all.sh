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
  echo "${0##*/} -a ACTION [-p PROFILE] [-r REGION] [-i BOOL] [-S OS] [-y]"
  echo -e "\t-a ACTION  owner, download, install, upgrade, uninstall, uninstall_yaml"
  echo -e "\t-p PROFILE AWS profile (default $profile)"
  echo -e "\t-r REGION  AWS region (default $region)"
  echo -e "\t-i BOOL    Enable Prisma CRI true or false (default automatic)"
  echo -e "\t-S OS      OS of the node workers: linux or windows (default $worker_os)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}

worker_os=linux
while getopts a:p:r:i:S:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    p) profile=$OPTARG ;;
    r) region=$OPTARG ;;
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
      ;;
    y) yes=-y ;;
    *) usage ;;
  esac
done
if ! type jq &>/dev/null; then
  echo ERROR jq is not installed, run sudo apt-get install jq 1>&2
  exit 3
fi
[[ ! $action ]] && usage
describe_all

clusters=($(jq -r '.[].name' $tmp))
declare -i skipped=0 errors=0 successes=0 total=0
for cluster in ${clusters[@]}; do
  total+=1

  echo === $cluster begin ===
  if ! kubectl config use-context $cluster &>/dev/null; then
    echo + eks-get-credentials.sh -p $profile -r $region -i $cluster 
    eks-get-credentials.sh -p $profile -r $region -i $cluster || continue
  fi
  args="-a $action -c $cluster -S $worker_os -C aws"
  [[ $yes ]] && args+=" $yes"
  [[ $cri ]] && args+=" -i $cri"
  echo + prisma-defender-helm.sh $args
  prisma-defender-helm.sh $args
  [[ $? -eq 0 ]] && successes+=1 || errors+=1
  echo -e "\n=== $cluster id $id end ===\n\n"
done

echo Errors: $errors
echo Successes: $successes
#echo Skipped: $skipped
echo Total: $total
