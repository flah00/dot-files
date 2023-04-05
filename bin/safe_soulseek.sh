#!/bin/bash
DIR=${DIR:-/nfs/music/Music}
WAIT=${WAIT:-20}
if [[ ! -d $DIR ]]; then
  declare -i andthen
  andthen=$WAIT
  echo -n waiting for $DIR 
  while [[ $andthen -gt 0 ]] ; do
    [[ -d $DIR ]] && break
    echo -n .
    sleep 1
    andthen+=-1
  done
  echo
  if [[ ! -d $DIR ]]; then
    echo $DIR never appeared
    exit 1
  fi
fi
LD_LIBRARY_PATH=/opt/openssl/default/lib $HOME/Applications/SoulseekQt-2018-1-30-64bit.AppImage
