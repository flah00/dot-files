#!/bin/bash -e
ifs="$IFS"
IFS="
"
export ME=$0
if [ $# -eq 0 ]; then
  cd /nfs/music/Music
  find . -maxdepth 1 -type d \! -name . -print0 | xargs -0 -L1 sh -c 'cd "$0" && pwd && $ME sub'
else
  pwd
  find . -maxdepth 1 -type d \! -name . -print0 | xargs -0 -L1 sh -c 'pwd && beet import -C -w -q "$0"'
fi
