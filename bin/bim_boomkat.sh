#!/bin/bash
trap 'exit 1' SIGINT SIGTERM
cd ~/Downloads/music

while getopts i arg; do
  case $arg in
    i) IMPORT_ONLY=true;;
    *) echo "${0##*/} [-i]"; exit 1;;
  esac
done

if [[ ! $IMPORT_ONLY ]]; then
  rm -ri *
  ls ../*zip
  echo -n 'import [Yn] '
  read ans
  ans=${ans:-y}
  if [[ ! $ans =~ ^y ]]; then
    echo nope
    exit 1
  fi
  for i in ../*zip; do 
    unzip "$i"
      set -x
    if [ "`ls *.mp3 *.m4a *.flac *.txt *.jpg`" != "" ]; then
      dir=`echo $i | sed 's,.*/\([^/]\+\).zip,\1,'`
      mkdir "$dir"
      mv -f *.mp3 *.m4a *.flac *.txt *.jpg "$dir"
      set +x
    fi
  done
fi

for i in *; do beet import -m "$i"; done

if [[ ! $IMPORT_ONLY ]]; then
  rm ../*zip
fi
