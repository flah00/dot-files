#!/usr/bin/env bash
console=us-east1.cloud.twistlock.com/us-2-158262739

while getopts u:ydh arg; do
  case $arg in
    u) console=$OPTARG ;;
    y) confirmed=true ;;
    d) downloaded=true ;;
    *)
      echo ${0##*/} [-u URL] [-y] [-d]
      echo -e "\t-u URL The prisma console URL (default $console)"
      echo -e "\t-y Do not confirm config options before running helm"
      echo -e "\t-d Do not download the helm chart, use the existing file ./twistlock-defender-helm.tar.gz"
      ;;
  esac
done

if [[ $downloaded = true ]]; then
  if [[ ! -f ./twistcli ]]; then
    echo "ERROR You must download twistlcli or do not specify -d flag" 1>&2
    exit 1
  fi

else
  # Format is either CSV or line 1 access key and line 2 secret, ie
  # Access Key ID,123-456-789
  # Secret Key,Somestring
  # OR
  # 123-456-789
  # Somestring
  if [[ -r ~philip.champon/.prisma ]]; then
    access_key_id=$(head -1 ~philip.champon/.prisma | sed 's/[^,]*,//')
    secret_key=$(tail -1 ~philip.champon/.prisma | sed 's/[^,]*,//')

  elif [[ -r ~/.prisma ]]; then
    access_key_id=$(head -1 ~/.prisma | sed 's/[^,]*,//')
    secret_key=$(tail -1 ~/.prisma | sed 's/[^,]*,//')

  else
    echo The prisma access key and secret are required to ${helm_action} cluster ${cluster_name}
    echo -n 'Access Key ID: '
    read access_key_id
    echo -n 'Secret Key: '
    read secret_key
  fi

  # obtain token, 30m lifetime
  echo Fetching token...
  token=$(curl -k \
    --silent \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"username":"'$access_key_id'", "password":"'$secret_key'"}' \
    https://$console/api/v1/authenticate)
  
  if [[ $token =~ ^\{\"err ]]; then
    echo -e "ERROR echo $token\n" 1>&2
    exit 1
  fi
  # strip json, ie {"token":" and "}
  token=${token##*token\":\"}
  token=${token%%\"\}}
  
  curl -k -O -q -L --header "Authorization: Bearer $token" https://$console/api/v1/util/twistcli
  chmod +x twistcli
fi

old=$(/opt/prisma/bin/twistcli --version 2>/dev/null) 
old=${old:-NOT INSTALLED}
new=$(./twistcli --version) 
if [[ $old != $new ]]; then
  echo "updating twistcli from '$old' to '$new'"
  set -x
  sudo mkdir -p /opt/prisma/bin
  sudo mv twistcli /opt/prisma/bin/twistcli 
else
  echo twistcli up to date
  rm -f twistcli 
fi
