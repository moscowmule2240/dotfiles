# dotfiles

## MacOS

### Rosetta (For Apple Silicon)
    $ softwareupdate --install-rosetta --agree-to-license

### Command Line Tools

#### Install

    $ xcode-select --install

### Homebrew

#### Install

    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

#### Install (For Apple Silicon)

    $ arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### zsh
    $ brew install zsh
    $ command -v zsh | sudo tee -a /etc/shells
    $ chsh -s $(command -v zsh)

### dotfiles

#### Install

    $ ./setup.sh

### login shell
「設定」->「ユーザとグループ」->「ユーザ名」右クリック->「詳細オプション」->「ログインシェル」変更 `/opt/homebrew/bin/zsh`

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

### %USERPROFILE%\.ssh
    $ mklink %USERPROFILE%\.ssh\config \\wsl$\Ubuntu\home\administrator\.ssh\config
    $ mklink %USERPROFILE%\.ssh\known_hosts %USERPROFILE%\Workspace\dotfiles\dotmine\ssh\known_hosts
    $ mklink /D %USERPROFILE%\.ssh\keys %USERPROFILE%\Workspace\dotfiles\dotmine\ssh\keys
