dotfiles
========

## Command Line Tools

> install

    $ xcode-select --install

## Homebrew

> install

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    $ brew install brew-file
    $ brew-file set_repo
    $ git@bitbucket.org:moscowmule2240/homebrew-file.git
    $ brew file install

## dotfiles

> install

    $ ./setup.sh

## pyenv
### install

> install

    $ brew install pyenv
    $ brew install pyenv-virtualenv

> update

    $ pyenv update

> python install

    $ pyenv install 2.7.6

> 切り替え

    $ pyenv local 2.7.6

* pyenv-virtualenv

> 仮想環境作成

    $ pyenv virtualenv 2.7.6 kemono-2.7.6

> 仮想環境選択

    $ pyenv local kemono-2.7.6

* mysql sandbox

> ダウンロード

    $ mkdir -p ~/opt/mysql/
TAR Archive をダウンロードする

> 作成

    $ tar zvxf mysql-x.x.x-***x86_64.tar.gz
    $ mv mysql-x.x.x-***x86_64 x.x.x
    $ make_sandbox x.x.x
    $ do you agree? ([Y],n) y

