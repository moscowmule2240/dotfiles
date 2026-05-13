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

### Amphetamine

`pmset disablesleep` だと「蓋閉じ防止」と「手動スリープ」を両立できないため、蓋閉じ抑止は Amphetamine (mas でインストール) に委譲する。

通常運用は素の macOS (蓋閉じ→スリープ、手動スリープも有効)。蓋を閉じても動かし続けたいときだけ手動でセッションを開始する。

#### 一般の設定

- セッションを速やかに開始: `右クリック (左クリックでメニューを表示)`
- 起動またはスリープ解除時の動作:
  - ログイン時に Amphetamine を起動: **OFF**
  - Amphetamine を起動するとき、自動的にセッションを開始: **OFF**
  - スリープを解除したとき、自動的にセッションを開始: **OFF**
- その他:
  - Dock から Amphetamine を隠す: **OFF**
  - 視覚効果を減らす: **OFF**

#### デフォルトセッションの設定

- デフォルト期間設定: `無期限に`
- 終了時間の計算: `タイマーを使用`
- 強制的にスリープ: **ON** (Mac が強制的にスリープされたときにセッションを終了)
- ディスプレイのスリープ: **ON** (ディスプレイのスリープを許可)
- Mac のディスプレイを閉じる: **OFF** (= 蓋を閉じてもシステムスリープを許可しない)
- スクリーンセーバ: **OFF**
- バッテリー残量によるセッション終了: **OFF**
- 電源アダプター関連の自動動作: **OFF**

#### 運用

- 通常の移動 (バッテリ駆動 + 蓋閉じ) は素のスリープで OK
- 蓋を閉じたまま動かし続けたいときだけメニューバーの Amphetamine から手動セッション開始 → 用が済んだら終了

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
