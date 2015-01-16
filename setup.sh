#!/bin/sh

current=`pwd`;

for file in ${current}/files/.*; do
  file_name=${file##*/}
  if [ ${file_name} != "." ] && [ ${file_name} != ".." ]; then
    echo "execute ln -s ${file} ~/${file_name}"
    ln -s ${file} ~/${file_name}
  fi
done

