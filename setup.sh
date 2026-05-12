#!/bin/bash

# .file
for file in ${PWD}/files/.*; do
  file_name=${file##*/}
  if [ ${file_name} != "." ] && [ ${file_name} != ".." ] && [ ${file_name} != ".config" ] && [ ${file_name} != ".zfunc" ]; then
    echo "execute ln -s ${file} $HOME/${file_name}"
    ln -s ${file} $HOME/${file_name}
  fi
done

# ssh
mkdir -p $HOME/.ssh/conf.d
ln -s $PWD/files/ssh/conf.d/config $HOME/.ssh/conf.d/config

# mise
mkdir -p $HOME/.config/mise
ln -s $PWD/files/.config/mise/config.toml $HOME/.config/mise/config.toml

# zfunc
mkdir -p $HOME/.zfunc
for f in ${PWD}/files/.zfunc/*; do
  echo "execute ln -s ${f} $HOME/.zfunc/${f##*/}"
  ln -s "${f}" "$HOME/.zfunc/${f##*/}"
done

# zsh
. $HOME/.zprofile

# brew
cat ${PWD}/brew/default.txt | xargs -L 1 -P 1 brew reinstall

# brew cask
brew tap oven-sh/bun
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/brew/cask.txt | xargs -L 1 -P 1 brew install cask --force
fi

# appstore
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/mas/default.txt | xargs -L 1 -P 1 mas install
fi

# remove cache
brew cleanup -s

# dotmine
bash dotmine/setup.sh

# pmset (macOS)
if [ "$(uname)" == 'Darwin' ]; then
  # 蓋を閉じてもスリープに入らない
  sudo pmset -a disablesleep 1
  # 1時間 (60分) 操作がなければスリープ
  sudo pmset -a sleep 60
fi

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

install_asdf_plugin() {
  local plugin=$1
  asdf plugin add $plugin
  asdf plugin update $plugin
  asdf install $plugin latest
  asdf set --home $plugin latest
}

install_asdf_plugin direnv
install_asdf_plugin uv
install_asdf_plugin nodejs
