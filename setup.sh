#!/bin/bash

# .file
# .gitconfig-macos は setup.sh で実体ファイルとして生成するので除外する
for file in ${PWD}/files/.*; do
  file_name=${file##*/}
  if [ ${file_name} != "." ] && [ ${file_name} != ".." ] && [ ${file_name} != ".config" ] && [ ${file_name} != ".zfunc" ] && [ ${file_name} != ".gitconfig-macos" ]; then
    echo "execute ln -s ${file} $HOME/${file_name}"
    ln -s ${file} $HOME/${file_name}
  fi
done

# ssh
mkdir -p $HOME/.ssh/conf.d
ln -s $PWD/files/ssh/conf.d/config $HOME/.ssh/conf.d/config

# mise config (symlink のみ。実体インストールは brew で mise を入れた後)
mkdir -p $HOME/.config/mise
ln -s $PWD/files/.config/mise/config.toml $HOME/.config/mise/config.toml

# uv config (Python は uv 管理のみ: python-preference = only-managed)
mkdir -p $HOME/.config/uv
ln -s $PWD/files/.config/uv/uv.toml $HOME/.config/uv/uv.toml

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
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/brew/cask.txt | xargs -L 1 -P 1 brew install cask --force
fi

# mise (config.toml の tool を一括インストール。bw / mas / awscli 等)
mise install

# appstore (mas 自体は mise でインストール済み)
if [ "$(uname)" == 'Darwin' ]; then
  cat ${PWD}/mas/default.txt | xargs -L 1 -P 1 mas install
fi

# remove cache
brew cleanup -s

# dotmine
bash dotmine/setup.sh

# pmset (macOS)
# 「蓋閉じでスリープしない」は disablesleep だと手動スリープも止まるので Amphetamine
# (mas で導入) に任せる。pmset は idle sleep のスケジュールだけ管理する。
if [ "$(uname)" == 'Darwin' ]; then
  # バッテリ駆動時は 60分 アイドルでスリープ
  sudo pmset -b sleep 60
  # 電源接続時はスリープしない
  sudo pmset -c sleep 0
fi

# git ssh signing (macOS)
# Claude Desktop など SSH_AUTH_SOCK が macOS 標準 ssh-agent socket に固定される
# 環境でも git 署名が通るよう、Bitwarden socket を強制する wrapper を指定する。
# gpg.ssh.{program,defaultKeyCommand} は ~ を展開しないため絶対パスで書き込む。
# 共通の macOS 用 git 設定 (将来用) は dotfiles の files/.gitconfig-macos を
# [include] で取り込む形で繋ぐ。
if [ "$(uname)" == 'Darwin' ]; then
  : > "$HOME/.gitconfig-macos"
  git config --file "$HOME/.gitconfig-macos" gpg.ssh.program "${PWD}/files/bin/ssh-keygen-bitwarden.sh"
  git config --file "$HOME/.gitconfig-macos" gpg.ssh.defaultKeyCommand "${PWD}/files/bin/ssh-add-bitwarden.sh -L"
  git config --file "$HOME/.gitconfig-macos" include.path "${PWD}/files/.gitconfig-macos"
fi

