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

### bash

#### Setup

    $ sudo vi /etc/shells
    $ add line `/usr/local/bin/bash`
    $ chsh -s /usr/local/bin/bash

### Windows

### WSL (Windows Subsystem for Linux)

#### Download
    https://docs.microsoft.com/ja-jp/windows/wsl/install-manual

#### Install (PowerShell)
    $ move .\Ubuntu_2004.2020.424.0_x64.appx .\Ubuntu_2004.2020.424.0_x64.zip
    $ Expand-Archive .\Ubuntu_2004.2020.424.0_x64.zip
    $ wsl.exe --import Ubuntu-20.04 D:\Applications\Ubuntu-20.04 .\Ubuntu_2004.2020.424.0_x64\install.tar.gz

#### Config (Ubuntu)
    $ apt update && sudo apt upgrade
    $ passwd root
    $ adduser administrator
    $ usermod -aG sudo administrator
    $ echo -e "[user]\ndefault=administrator\n[interop]\nappendWindowsPath=false" > /etc/wsl.conf

#### Restart (PowerShell)
    $ wsl.exe --terminate Ubuntu-20.04

#### Config (Windows Terminal)
「設定」→「ディレクトリの開始」

    \\wsl$\Ubuntu-20.04\home\administrator

### Homebrew

#### Install

    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # brew next step
    $ eval "$(/home/administrator/.linuxbrew/bin/brew shellenv)"
    $ sudo apt-get install build-essential
    $ brew install gcc

### Workspace
    $ ln -s /mnt/c/Users/{username}/Workspace ~/Workspace

### zsh
    $ brew install zsh
    $ command -v zsh | sudo tee -a /etc/shells
    $ chsh -s $(command -v zsh)

### dotfiles

#### Install
    $ ./setup.sh

### ssh
    # chmod 600 ~/.ssh/config
