#!/usr/bin/env bash
# Apply the given action to all of the clusters for the given subscription
# -a ACTION install, upgrade, uninstall, uninstall_yaml
# -s SUB azure subscription
shopt -s expand_aliases
alias gcloud='gcloud --verbosity error '
shopt -s nocasematch
# projects/157690393260/zones/us-central1-a -> us-central1-a
zone=$(curl --silent http://metadata/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | sed 's,.*/,,')
# zone to region...
zone=${zone%-[a-z]}
tmp=/tmp/$$.gc.gke.list
trap 'rm -f $tmp' EXIT
trap 'exit 1' TERM INT
function usage() {
  echo "${0##*/} -a ACTION [-z ZONE] [-p PROJECT] [-m PATTERN] [-o PATH] [-i BOOL] [-S OS] [-y]"
  echo -e "\t-a ACTION  download, install, upgrade, status, pods, uninstall, uninstall_yaml" 
  echo -e "\t-z ZONE    Google zone to search"
  echo -e "\t-p PROJECT Google project (default ALL)"
  echo -e "\t-m PATTERN Only apply the ACTION to cluster names matching PATTERN"
  echo -e "\t-o PATH    Write results to PATH as CSV for owner, status, or pods"
  echo -e "\t-i BOOL    Enable Prisma CRI true or false (default automatic)"
  echo -e "\t-S OS      OS of the node workers: linux or windows (default $worker_os)"
  echo -e "\t-y         Yes to all prompts"
  exit 1
}
function skip() { clusters_skip+=($1); }
function error() { clusters_error+=($1); }

worker_os=linux
while getopts a:z:p:m:o:i:S:hy arg; do
  case $arg in
    a) action=$OPTARG ;;
    z) 
      zone=$OPTARG ;;
    p) 
      gcloud config set project $OPTARG 
      export GOOGLE_CLOUD_PROJECT=$OPTARG
      ;;
    m) match=$OPTARG ;;
    o) csv=$OPTARG ;;
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
case $zone in
  us-central1*) project_ignore='prod|eu-dev' ;;
  europe-west3*) project_ignore='prod|us-dev' ;;
  us-east1*) project_ignore='dev|eu-prod' ;;
  europe-west1*) project_ignore='dev|us-prod' ;;
  *) echo WARN Unsupported zone \'$zone\' 1>&2 ;;
esac
[[ ! $action ]] && usage

declare -a projects
if [[ $GOOGLE_CLOUD_PROJECT ]]; then
  projects=($GOOGLE_CLOUD_PROJECT)
elif [[ ! $project_ignore ]]; then
  echo WARN Not filtering projects, try specifying a zone or region 1>&2
  projects=$(gcloud projects list --format='value(projectId)')
else
  projects=$(gcloud projects list --format='value(projectId)' | grep -Ev "$project_ignore")
fi

if [[ ! -r ~philip.champon/.prisma && ! -r ~/.prisma && ! $yes ]]; then
  echo WARN .prisma file not found, you will be required to input prisma key and secret ${#clusters[@]} times
  echo WARN Alternatively, you can generate a key and secret, as a cloud-provisioning-admin in prisma
  echo WARN https://app2.prismacloud.io/settings/access_control/access_keys and copy the csv to ~/.prisma
  echo -n "Continue [Y/n] "
  read accept
  [[ $accept != "" && ! $accept =~ ^y(es)? ]] && exit 2
fi
declare -i successes=0 total=0
declare -a clusters_skip clusters_error
TEE=$(mktemp /tmp/${0##*/}XXXX)
[[ $action = owner && $csv ]] && echo "Cluster,Owner" > $csv
[[ $action = status && $csv ]] && echo "Cluster,Prisma Chart Version" > $csv
[[ $action = pods && $csv ]] && echo "Cluster,Prisma Pod Name,Status" > $csv
[[ $zone ]] && filter="zone ~ $zone"
for project in ${projects[@]}; do
  set -x
  gcloud config set project $project
  gcloud container clusters list --filter="$filter" --format='json(name,status,zone,autopilot.enabled,resourceLabels.owner,resourceLabels.Owner)'  >$tmp
  set +x

  if [[ $match ]]; then
    clusters=($(jq -r '.[].name | select(contains("'"$match"'"))' $tmp))
  else
    clusters=($(jq -r '.[].name' $tmp))
  fi
  echo Found ${#clusters[@]} in project $project

  for cluster in ${clusters[@]}; do
    total+=1
    state=$(jq -r '.[] | select(.name=="'$cluster'") | .status' $tmp)
    autopilot=$(jq -r '.[] | select(.name=="'$cluster'") | .autopilot.enabled' $tmp)
    [[ $autopilot != true ]] && unset autopilot

    echo $(tput rev)=== $cluster begin ===$(tput sgr0)

    if [[ $action = debug ]]; then
      if [[ $state != Running ]]; then
        echo "WARN Skipping cluster $cluster state '$state'"
        skip $cluster
        echo -e "\n=== $cluster id $id end ===\n\n"
        continue
      fi
      if ! kubectl config use-context $cluster || ! gke-get-credentials.sh -I -i $cluster; then
        echo WARN Skipping cluster $cluster, context not defined
        skip $cluster
        echo -e "\n=== $cluster id $id end ===\n\n"
        continue
      fi
      nodes=($(kubectl --request-timeout=3s get node -o jsonpath={..name} -l kubernetes.io/os=$worker_os))
      for node in ${nodes[@]}; do
        echo $(tput setaf 1)To access the worker node:$(tput sgr0) $(tput rev)exec chroot /host$(tput sgr0)
        echo + kubectl --request-timeout=3s debug node/$node --image=busybox -ti 1>&2
        kubectl --request-timeout=3s debug node/$node --image=busybox -ti
        [[ $? -eq 0 ]] && successes+=1 || error $cluster
        #kubectl --request-timeout=3s delete pod -l app=debug
      done

    elif [[ $action = owner ]]; then
      set -x; owner=$(jq -r '.[] | select(.name=="'$cluster'") | if(.resourceLabels.owner) then .resourceLabels.owner else .resourceLabels.Owner end' $tmp); set +x
      # replace weird formatting in label
      owner=${owner//_/.}
      owner=${owner//-/ }
      echo Owner $owner
      [[ $csv ]] && echo "\"$cluster\",\"$owner\"" >> $csv
      [[ $owner = null || ! $owner ]] && error $cluster || successes+=1

    elif [[ $state = RUNNING ]]; then
      args="-a $action -c $cluster -S $worker_os -C google"
      [[ $yes ]] && args+=" $yes"
      [[ $cri ]] && args+=" -i $cri"
      [[ $autopilot ]] && args+=" -A"
      echo + prisma-defender-helm.sh $args
      prisma-defender-helm.sh $args | tee $TEE
      [[ $(echo "${PIPESTATUS[@]}" | tr -s ' ' + | bc) -eq 0 ]] && successes+=1 || error $cluster
      if [[ $csv && $action = status ]]; then
        ver=$(grep twistlock $TEE | awk '{print$9}')
        echo "\"$cluster\",\"$ver\"" >> $csv
      # mark clusters that lack pods
      elif [[ $csv && $action = pods && $(wc -l $TEE| awk '{print$1}') -lt 2 ]]; then
        echo "\"$cluster\",,NO PODS" >> $csv
      # or collec details
      elif [[ $csv && $action = pods ]]; then
        ifs="$IFS"
        IFS="
        "
        for p in $(grep twistlock $TEE | awk '{printf "\"%s\",\"%s\"\n", $1, $3}'); do 
          echo "\"$cluster\",$p" >> $csv
        done
        IFS="$ifs"
      fi

    else
      echo "WARN Skipping cluster $cluster state '$state'"
      skip $cluster
      echo -e "\n=== $cluster end ===\n\n"
      continue
    fi
    echo -e "\n=== $cluster end ===\n\n"
  done
done

echo Errors: ${#clusters_error[@]}
[[ ${#clusters_error[@]} -gt 0 ]] && echo -e "\t${clusters_error[@]}"
echo Successes: $successes
echo Skipped: ${#clusters_skip[@]}
[[ ${#clusters_skip[@]} -gt 0 ]] && echo -e "\t${clusters_skip[@]}"
echo Total: $total
exit ${#clusters_error[@]}

