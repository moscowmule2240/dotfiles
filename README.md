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

### GUI アプリの PATH (launchd)

Dock / Spotlight / Launchpad から起動したアプリは zsh を経由しないため、PATH は zsh の設定ではなく
launchd の user domain の既定値 (`/usr/bin:/bin:/usr/sbin:/sbin`) になり `/usr/local/bin` を含まない。

これが実際に問題になる例が PyCharm の Docker 連携。`~/.docker/config.json` の
`"credsStore": "desktop"` によって docker CLI は `docker-credential-desktop` を PATH から探すが、
その実体は `/usr/local/bin/docker-credential-desktop` (Docker.app 内への symlink) にしかないため、
Dock から起動した PyCharm では解決できず認証エラーになる。ターミナルから起動した場合は
zsh の PATH を継承するので再現しない。

launchd の user domain の既定 PATH に `/usr/local/bin` を足して解決する。

    sudo launchctl config user path /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

- **再起動が必要。** このコマンドは `/private/var/db/com.apple.xpc.launchd/config/user.plist` を
  書くだけで、読まれるのは次回 boot 時
- 設定内容の確認: `sudo plutil -p /private/var/db/com.apple.xpc.launchd/config/user.plist`
  (`launchctl config` に現在値を表示するサブコマンドは無い)
- 再起動後の実効値の確認: `launchctl getenv PATH`
- 解除: 上記 plist を削除して再起動

Homebrew (`/opt/homebrew/bin`) と mise の shims は意図的に含めていない。GUI アプリに渡すのは
Apple 標準 + Docker Desktop の CLI までに絞り、GUI から起動したアプリが mise/brew 管理下の
バージョンを暗黙に拾わないようにする (シェル側は zsh の設定で解決済み)。

却下した代替案:

- `credsStore` を外す → 資格情報が `~/.docker/config.json` に平文で載るため却下
- PyCharm をターミナルから起動する → Dock から起動するという前提を崩すため却下
- credential helper を `/usr/bin` に置く → SIP 保護下で書き込めない

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

### tools (mise)

`setup.ps1` が `choco install mise` で mise を導入し、`~/.config/mise/config.toml`
(macOS と共通) の tool を `mise install` で一括インストールします。
mas / redis / direnv は config.toml の `os` 指定で Windows ではスキップされます。

#### 個別に追加する場合

    mise use -g node@latest
    mise use -g bun@latest
    mise use -g claude-code@latest
