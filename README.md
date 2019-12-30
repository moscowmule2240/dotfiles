dotfiles
========

## Command Line Tools

> Install

    $ xcode-select --install

## Homebrew

> Install

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    $ sudo mkdir -p $(brew --prefix)/Frameworks
    $ sudo chown -R $(whoami) $(brew --prefix)/Frameworks

## dotfiles

> Install

    $ ./setup.sh

## bash

> Setup

    $ sudo vi /etc/shells
    $ add line `/usr/local/bin/bash`
    $ chsh -s /usr/local/bin/bash
