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

## Windows

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
    $ chmod 600 ~/.ssh/config

### Command Prompt
    $ mkdir %USERPROFILE%\.ssh
    $ mklink %USERPROFILE%\.ssh\id_ed25519 %USERPROFILE%\Workspace\dotfiles\dotmine\ssh\keys\default\id_ed25519
    $ mklink %USERPROFILE%\.ssh\id_ed25519.pub %USERPROFILE%\Workspace\dotfiles\dotmine\ssh\keys\default\id_ed25519.pub
    $ mklink %USERPROFILE%\.gitconfig %USERPROFILE%\Workspace\dotfiles\files\.gitconfig
    $ mklink %USERPROFILE%\.gitignore_global %USERPROFILE%\Workspace\dotfiles\files\.gitignore_global

## VPS

### Upgrade
    $ sudo apt update
    $ sudo apt list --upgradable
    $ sudo apt upgrade

### User
    $ sudo adduser administrator

### Sudo
    $ sudo gpasswd -a administrator sudo

### Change User
    $ su administrator
    $ cd

### Homebrew

#### Install
    $ sudo apt install git

    $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # brew next step
    $ eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    $ sudo apt-get install build-essential
    $ brew install gcc

### Workspace
    $ mkdir Workspace

### zsh
    $ brew install zsh
    $ command -v zsh | sudo tee -a /etc/shells
    $ chsh -s $(command -v zsh)

### dotfiles

#### Install
    $ ./setup.sh

### ssh
    $ chmod 600 ~/.ssh/config

#### config
    $ sudo vi /etc/ssh/sshd_config.d/sshd.config

    PasswordAuthentication no
    ClientAliveInterval 60
    ClientAliveCountMax 30
    PermitRootLogin no

### Wine
    $ mkdir /home/administrator/Workspace/wine
    $ cd /home/administrator/Workspace/wine

    $ dpkg --add-architecture i386
    $ wget -nc https://dl.winehq.org/wine-builds/winehq.key
    $ apt-key add winehq.key
    $ apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'
    $ wget https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_22.04/Release.key
    $ apt-key add Release.key
    $ apt-add-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_22.04/ ./'
    $ apt update
    $ apt install --install-recommends winehq-stable

### Localize
    $ apt -y install language-pack-ja-base language-pack-ja ibus-mozc
    $ localectl set-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja"
    $ source /etc/default/locale
    $ timedatectl set-timezone Asia/Tokyo

### Ubuntu Mate
    $ apt-get install xrdp
    $ apt install tasksel
    $ tasksel
    $ sudo tasksel install mate-desktop
      select -> [lightdm]
    $ reboot

### Fonts
    $ scp /mnt/c/Windows/Fonts/msgothic.ttc moscowmule2240-ea.myddns.me:~/.wine/drive_c/windows/Fonts/
    $ scp /mnt/c/Windows/Fonts/webdings.ttf moscowmule2240-ea.myddns.me:~/.wine/drive_c/windows/Fonts/
    $ scp /mnt/c/Windows/Fonts/wingding.ttf moscowmule2240-ea.myddns.me:~/.wine/drive_c/windows/Fonts/
    $ reboot

### EA

#### Install
    $ wget -nc https://download.mql5.com/cdn/web/tradexfin.limited/mt4/xmtrading4setup.exe
    「Wine Windowsプログラムローダーで開く」をクリック

#### EA
    $ cp ~/Workspace/MT4/grandia.ex4 ~/.wine/drive_c/Program\ Files\ \(x86\)/XMTrading\ MT4/MQL4/Experts/
