#!/bin/sh

current=`pwd`;

# .file
for file in ${current}/files/.*; do
  file_name=${file##*/}
  if [ ${file_name} != "." ] && [ ${file_name} != ".." ]; then
    echo "execute ln -s ${file} ~/${file_name}"
    ln -s ${file} ~/${file_name}
  fi
done

# reload
source ~/.bash_profile

# brew
while read application
do
  echo $ brew reinstall ${application}
  brew reinstall ${application}
done < ${current}/brew/default.txt

# brew cask
while read application
do
  echo $ brew cask reinstall ${application}
  brew cask reinstall ${application}
done < ${current}/brew/cask.txt

# appstore
while read application
do
  id=$(awk '{print $1}' <<< ${application})
  echo $ mas install ${id}
  mas install ${id}
done < ${current}/mas/default.txt

# remove cache
brew cleanup -s

# dotmine
sh dotmine/setup.sh
