dotfiles
========

## Command Line Tools

> install

    $ xcode-select --install

## Homebrew

> install

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    $ brew install rcmdnk/file/brew-file
    $ brew-file set_repo
    $ git@github.com:moscowmule2240/homebrew-file.git
    $ brew file install

## dotfiles

> install

    $ ./setup.sh

## bash

> setup

    $ sudo vi /etc/shells
    $ add line `/usr/local/bin/bash`
    $ chsh -s /usr/local/bin/bash

## pyenv
### install

> install

    $ brew install pyenv
    $ brew install pyenv-virtualenv

> update

    $ pyenv update

> python install

    $ pyenv install 2.7.12

> 切り替え

    $ pyenv local 2.7.12

* pyenv-virtualenv

> 仮想環境作成

    $ pyenv virtualenv 2.7.12 default

> 仮想環境選択（グローバル）

    $ pyenv global default

> 仮想環境選択（ローカル：ディレクトリ単位）

    $ pyenv local default

> 現在の仮想環境の確認

    $ pyenv version
    $ pyenv versions

