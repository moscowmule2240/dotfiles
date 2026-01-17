# dotfiles

## MacOS

### Command Line Tools

#### Install

    xcode-select --install

### Homebrew

#### Install

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### zsh
    brew install zsh
    command -v zsh | sudo tee -a /etc/shells
    chsh -s $(command -v zsh)

### dotfiles

#### Install

    ./setup.sh

### login shell
「設定」->「ユーザとグループ」->「ユーザ名」右クリック->「詳細オプション」->「ログインシェル」変更 `/opt/homebrew/bin/zsh`

## Windows

### ssh

    Services → OpenSSH Authentication Agent
    set the Startup type setting to Disabled

    Bitwarden Enable SSH agent

### dotfiles

#### Install

    $ ./setup.ps1

### chocolatey

#### Install

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

### tools

#### Install

##### 管理者権限あり PowerShell

    choco install volta

##### 管理者権限なし PowerShell

    volta install node@latest
    volta install bun@latest
    volta install @anthropic-ai/claude-code@latest
