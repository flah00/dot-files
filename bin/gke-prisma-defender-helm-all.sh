#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_caas2
# -s SUB azure subscription
sub=$GOOGLE_CLOUD_PROJECT
tmp=/tmp/$$.gc.gke.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-s SUB]"
  echo -e "\t-a ACTION install, upgrade, uninstall, uninstall_caas2"
  echo -e "\t-s SUB    Azure subscription (default $sub)"
  exit 1
}

while getopts a:p:h arg; do
  case $arg in
    a) action=$OPTARG ;;
    p)
      gcloud config set project $OPTARG
      ;;
    *) usage ;;
  esac
done
[[ ! $action ]] && usage
set -x; gcloud container clusters list --format=json >$tmp; set +x

clusters=($(jq -r '.[][0]' $tmp))
for cluster in ${clusters[@]}; do
  cluster_short=$(echo $cluster | sed 's/-cluster$//i')
  cluster_short=${cluster:0:20}

  echo === $cluster short $cluster_short begin ===
  if ! kubectl config get-contexts | grep -q $cluster; then
    set -x; gke-get-credentials.sh -i $id; set +x
    if [[ $? -ne 0 ]]; then
      echo Skipping $cluster, failed to fetch kubectl credentials
      continue
    fi
  fi
  set -x; prisma-defender-helm.sh -a $action -c $cluster -n $cluster_short; set +x
  echo
  echo === $cluster end ===
done

