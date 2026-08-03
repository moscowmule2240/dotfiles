#!/usr/bin/env zsh

# よく使うソフトウェアをまとめて最新化する
# onedrive のように cask 名と formula 名が衝突するパッケージがあるので、
# --cask / --formula を明示して呼び分ける。
# brew 6.0 以降は upgrade 前に [y/n] を聞く ask mode が既定なので --yes で無効化する。
# 環境変数 HOMEBREW_NO_ASK でも消せるが、それだと手打ちの brew upgrade まで
# 無確認になるため、対象を明示しているこの関数の中だけに閉じる。
update-tools() {
  brew update
  brew upgrade --yes --cask \
    antigravity-cli \
    antigravity-ide \
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
  brew upgrade --yes --formula \
    htop \
    mise \
    zsh \
    zsh-completions \
    zsh-git-prompt
  # mise 管理に移したもの (旧 brew formula 相当)
  # --yes: 確認プロンプトを自動承諾して対話なしで進める
  mise upgrade --yes bitwarden gh
  brew cleanup -s
}
