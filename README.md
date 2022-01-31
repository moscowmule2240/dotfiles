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

#### Install (PowerShell)
    $ wsl --install -d Ubuntu

    Enter new UNIX username: administrator
    New password: any
    Retype new password: any

#### Config (Ubuntu)
    $ sudo apt update && sudo apt upgrade
    $ sudo sh -c "echo '[interop]\nappendWindowsPath=false' > /etc/wsl.conf"

#### Restart (PowerShell)
    $ wsl --terminate Ubuntu

#### Config (Windows Terminal)
「設定」→「ディレクトリの開始」

    \\wsl$\Ubuntu\home\administrator

### Homebrew

#### Install

    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # brew next step
    $ eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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
