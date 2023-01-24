#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
sub=b1e119d0-b7fa-451d-af39-0611d33b30dc
tmp=/tmp/$$.az.aks.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-s SUB] [-m PATTERN] [-o PATH] [-i BOOL] [-R REGION] [-S OS] [-y]"
  echo -e "\t-a ACTION  download, install, history, rollback, upgrade, status, pods, uninstall" 
  echo -e "\t-m PATTERN Only apply the ACTION to cluster names matching PATTERN"
  echo -e "\t-s SUB     Azure subscription (default $sub)"
  echo -e "\t-o PATH    Write results to PATH as CSV for owner, status, or pods"
  echo -e "\t-R REGION  The account region, ie AMR, APA, EMEA, India (default $account_region)"
  echo -e "\t-S OS      OS of the node workers: linux or windows (default $worker_os)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}
function skip() { clusters_skip+=($1); }
function error() { clusters_error+=($1); }

account_region=$(az account show --query 'name')
while getopts a:s:m:o:R:S:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    s) sub=$OPTARG ;;
    m) match=$OPTARG ;;
    o) csv=$OPTARG ;;
    R) account_region=$OPTARG ;;
    y) yes=-y ;;
    S)
      case $OPTARG in
        l*) worker_os=linux ;;
        w*) worker_os=windows ;;
        *) usage 2 ;;
      esac
      ;;
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
az aks list --query '[].{cn:name, rg:resourceGroup, state:powerState.code}' >$tmp 
set +x

if [[ $match ]]; then
  clusters=($(jq -r '.[].cn | select(contains("'"$match"'"))' $tmp))
else
  clusters=($(jq -r '.[].cn' $tmp))
fi
echo Found ${#clusters[@]}
[[ $action = status && $csv ]] && echo "Cluster,Fluentbit Chart Version" > $csv
[[ $action = pods && $csv ]] && echo "Cluster,Fluentbit Pod Name,Status" > $csv

declare -i successes=0 total=0
declare -a clusters_skip clusters_error
TEE=$(mktemp /tmp/${0##*/}XXXX)
for cluster in ${clusters[@]}; do
  total+=1
  state=$(jq -r '.[] | select(.cn=="'$cluster'") | .state' $tmp)
  echo === $cluster begin ===

  if [[ $state = Running ]]; then
    args="-a $action -c $cluster-admin -n $cluster -C azure"
    [[ $worker_os ]] && args+=" -S $worker_os"
    [[ $account_region ]] && args+=" -R $account_region"
    [[ $yes ]] && args+=" $yes"
    echo + siem-helm.sh $args
    siem-helm.sh $args | tee $TEE
    [[ $(echo "${PIPESTATUS[@]}" | tr -s ' ' + | bc) -eq 0 ]] && successes+=1 || error $cluster
    if [[ $csv && $action = status ]]; then
      ver=$(grep soc $TEE | awk '{print$9}')
      echo "\"$cluster\",\"$ver\"" >> $csv
    elif [[ $csv && $action = pods ]]; then
      ifs="$IFS"
      IFS="
"
      for p in $(grep soc $TEE | awk '{printf "\"%s\",\"%s\"\n", $1, $3}'); do 
        echo "\"$cluster\",$p" >> $csv
      done
      IFS="$ifs"
    fi

  else
    echo "WARN Skipping $cluster, state is '$state'"
    [[ $csv ]] && echo "\"$cluster\",$id,\"$cluster_short\"," >> $csv
    skip $cluster
  fi
  echo -e "\n=== $cluster end ===\n\n"
done

rm -rf /tmp/*siem-helm*
echo Errors: ${#clusters_error[@]}
[[ ${#clusters_error[@]} -gt 0 ]] && echo -e "\t${clusters_error[@]}"
echo Successes: $successes
echo Skipped: ${#clusters_skip[@]}
[[ ${#clusters_skip[@]} -gt 0 ]] && echo -e "\t${clusters_skip[@]}"
echo Total: $total
exit ${#clusters_error[@]}

