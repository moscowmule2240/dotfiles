#!/usr/bin/env zsh

# よく使うソフトウェアをまとめて最新化する
# onedrive のように cask 名と formula 名が衝突するパッケージがあるので、
# --cask / --formula を明示して呼び分ける。
update-tools() {
  brew update
  brew upgrade --cask \
    antigravity \
    bitwarden \
    claude \
    claude-code@latest \
    comet \
    docker-desktop \
    google-chrome \
    iterm2 \
    mysqlworkbench \
    onedrive \
    pycharm \
    visual-studio-code
  brew upgrade --formula \
    htop \
    mise \
    zsh \
    zsh-completions \
    zsh-git-prompt
  # mise 管理に移したもの (旧 brew formula 相当)
  mise upgrade bitwarden gh
  brew cleanup -s
}
