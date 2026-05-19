#!/usr/bin/env zsh

# よく使うソフトウェアをまとめて最新化する
update-tools() {
  brew update
  brew upgrade \
    antigravity \
    bitwarden \
    bitwarden-cli \
    claude \
    claude-code@latest \
    comet \
    docker-desktop \
    gh \
    google-chrome \
    htop \
    iterm2 \
    mise \
    mysqlworkbench \
    onedrive \
    pycharm \
    visual-studio-code \
    zsh \
    zsh-completions \
    zsh-git-prompt
  brew cleanup -s
}
