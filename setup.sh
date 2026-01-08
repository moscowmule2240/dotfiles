#!/bin/bash

# .file
for file in ${PWD}/files/.*; do
  file_name=${file##*/}
  if [ ${file_name} != "." ] && [ ${file_name} != ".." ]; then
    echo "execute ln -s ${file} $HOME/${file_name}"
    ln -s ${file} $HOME/${file_name}
  fi
done

# ssh
mkdir -p $HOME/.ssh/conf.d
ln -s $PWD/files/ssh/conf.d/config $HOME/.ssh/conf.d/config

# zsh
. $HOME/.zprofile

# brew
cat ${PWD}/brew/default.txt | xargs -L 1 -P 1 brew reinstall

# brew cask
brew tap oven-sh/bun
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/brew/cask.txt | xargs -L 1 -P 1 brew install --cask --force
fi

# appstore
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/mas/default.txt | xargs -L 1 -P 1 mas install
fi

# remove cache
brew cleanup -s

# dotmine
bash dotmine/setup.sh
