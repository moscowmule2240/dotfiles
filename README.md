# dotfiles

## MacOS

### Command Line Tools

#### Install

    $ xcode-select --install

### Homebrew

#### Install

    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### zsh
    $ brew install zsh
    $ command -v zsh | sudo tee -a /etc/shells
    $ chsh -s $(command -v zsh)

### dotfiles

#### Install

    $ ./setup.sh

### login shell
「設定」->「ユーザとグループ」->「ユーザ名」右クリック->「詳細オプション」->「ログインシェル」変更 `/opt/homebrew/bin/zsh`

## Windows

### Local

#### ssh

    Services → OpenSSH Authentication Agent
    set the Startup type setting to Disabled

    Bitwarden Enable SSH agent

#### dotfiles

##### Install

    $ ./setup.ps1
