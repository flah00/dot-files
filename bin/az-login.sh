#!/bin/bash
# Should only attempt to login every 12 hours (based on mtime ~/.azure/az.sess)
# Print a list of available tenants
# az-login.sh -p
# Login to one of the available tenants, by name
# az-login.sh -n TfO-Azure-EU-Dev
# Or by Azure domain
# az-login.sh -d azeudev
# Or by tenant id
# az-login.sh -t 797f4846-ba00-4fd7-ba43-dac1f8f63013
OUTPUT=$(mktemp /tmp/${0##*/}-XXXXXXX)
trap 'rm -f $OUTPUT' EXIT INT TERM
usage() {
  echo "${0##*/} {-n NAME | -d DOMAIN | -t TENANT_ID | -p} [-f]"
  echo -e "\t-n NAME      Azure tenant name"
  echo -e "\t-d DOMAIN    Azure directory name"
  echo -e "\t-t TENANT_ID Azure tenant id"
  echo -e "\t-p           Print available tenants"
  echo -e "\t-f           Force login to run"
  exit ${1:-0}
}
get_tenants() {
  echo + az account list --query '[].{name:name, tenantId:tenantId, user:user.name}' 1>&2
  az account list --query '[].{name:name, tenantId:tenantId, user:user.name}' > $OUTPUT
}
get_tenant_id_by_name() {
  [[ ! -s $OUTPUT ]] && get_tenants
  echo + jq -r '.[] | select(.name=="'$1'") | .tenantId' $OUTPUT 1>&2
  id=$(jq -r '.[] | select(.name=="'${1:?Missing tenant name}'") | .tenantId' $OUTPUT)
  ex=$?
  echo $id
  [[ ! $id || $ex -gt 0 ]] && return 1 || return 0
}
while getopts n:d:t:pfh arg; do
  case $arg in
    n) tenant=$(get_tenant_id_by_name $OPTARG) ;;
    d)
      case $OPTARG in
        azeudev) tenant=$(get_tenant_id_by_name TfO-Azure-EU-Dev) ;;
        azeuprod) tenant=$(get_tenant_id_by_name TfO-Azure-EU-Prod) ;;
        *) echo "ERROR domain '$domain' unknown"; exit 2 ;;
      esac
      ;;
    t) tenant=$OPTARG ;;
    p) print=true ;;
    f) force=true ;;
    *) usage ;;
  esac
done
if ! type jq &>/dev/null; then
  echo ERROR jq is not installed, run sudo apt-get install jq 1>&2
  exit 3
fi

[[ $(uname -s) = Darwin ]] && stat=$(stat -f '%m' ~/.azure/az.sess) || stat=$(stat -c '%Z' ~/.azure/az.sess)
now=$(date +%s)
## session file written to more than 12h ago
[[ ! $force && $((now-stat)) -lt $((now-43200)) ]] && echo You seem to be logged in && exit

if [[ $print ]]; then
  get_tenants
  echo Available tenants
  jq -r '.[] | "name: \(.name) id: \(.tenantId) "' $OUTPUT
elif [[ $tenant ]]; then
  echo + az login --tenant $tenant 1>&2
  az login --tenant $tenant
else
  echo ERROR tenant empty
  usage 2
fi

