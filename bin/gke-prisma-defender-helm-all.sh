#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
project=$GOOGLE_CLOUD_PROJECT
tmp=/tmp/$$.gc.gke.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-p PROJECT] [-y]"
  echo -e "\t-a ACTION  install, upgrade, uninstall, uninstall_caas2"
  echo -e "\t-p PROJECT Google project (default $project)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}

while getopts a:p:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    p) gcloud config set project $OPTARG ;;
    y) yes=-y ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
set -x; gcloud container clusters list --format=json >$tmp; set +x

clusters=($(jq -r '.[][0]' $tmp))
declare -i skipped=0 errors=0 successes=0 total=0
for cluster in ${clusters[@]}; do
  total+=1
  cluster_short=$(echo $cluster | sed 's/-cluster$//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short begin ===
  echo + prisma-defender-helm.sh $yes -a $action -c $cluster -n $cluster_short -C google
  prisma-defender-helm.sh $yes -a $action -c $cluster -n $cluster_short
  [[ $? -eq 0 ]] && successes+=1 || errors+=1
  echo -e "\n=== $cluster id $id end ===\n\n"
done

echo Errors: $errors
echo Successes: $successes
#echo Skipped: $skipped
echo Total: $total
