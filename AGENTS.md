# AGENTS.md

このリポジトリで AI コーディングエージェント (Claude Code / Copilot / Codex / Antigravity 等) が作業するためのガイド。

## リポジトリ概要

macOS / Windows 両対応の個人 dotfiles。ビルド・テスト・lint は存在しない。
セットアップスクリプトがシンボリックリンクを張り、パッケージマネージャーを順に呼ぶ構成。

## 公開リポジトリとしての制約

この dotfiles リポジトリは **public**。以下をコミットに含めないこと。

- 秘密情報 (SSH 秘密鍵、API キー・トークン、パスワード、ライセンスキー等)
- ユーザーを特定できる情報 (氏名、メールアドレス、勤務先、ホスト名・IP アドレス等)
- `/Users/<ユーザー名>` のようなユーザー名を含む絶対パス。スクリプトは `$HOME` / `${PWD}` /
  `$PSScriptRoot` 等で書き、絶対パスが必要な設定はコミットせず setup 時に生成する
  (既存の例: `.gitconfig-macos` は setup.sh が `git config --file` で実体を生成)

公開できない個人設定・秘密は dotmine サブモジュール (private) 側に置く。
該当する情報をコミットに含めそうになった場合は、コミットせずユーザーに確認する。

## コマンド

| コマンド | 用途 |
|---|---|
| `./setup.sh` | macOS セットアップ本体 (Homebrew / zsh は README の手順で事前導入) |
| `./setup.ps1` | Windows セットアップ本体 (管理者権限で自動再起動する) |
| `update-tools` | 常用ツール一括更新 (zsh 関数、[files/.zfunc/update-tools.zsh](files/.zfunc/update-tools.zsh)) |

セットアップ全体を再実行して検証する手段はない (`ln -s` は既存リンクがあると失敗する
非冪等な作り)。変更の検証は該当ステップのコマンドを単体で流すこと。

## アーキテクチャ

### シンボリックリンク戦略

実体はすべてリポジトリ内に置き、`$HOME` へはリンクのみ張る。

- `files/.*` → `$HOME/` 直下 (setup.sh のループ。`.config` / `.zfunc` / `.gitconfig-macos` は除外し個別処理)
- `files/.config/{mise,uv}/` → `~/.config/` 配下へファイル単位でリンク
- `files/.zfunc/*` → `~/.zfunc/` (zsh の fpath / autoload 用)
- `.gitconfig-macos` だけは例外で、setup.sh が `git config --file` で **実体ファイルを生成**する
  (絶対パスが必要な Bitwarden SSH 署名 wrapper の設定のため)

### パッケージ管理の役割分担

1 つのツールを複数のマネージャーで管理しない。追加先は以下で判断する。

| マネージャー | 定義ファイル | 対象 |
|---|---|---|
| brew formula | `brew/default.txt` | macOS のビルド依存・シェル環境 (zsh 等) |
| brew cask | `brew/cask.txt` | macOS GUI アプリ |
| mise | `files/.config/mise/config.toml` | クロスプラットフォームの CLI ツール (`os = [...]` で OS を絞る) |
| mas | `mas/default.txt` | Mac App Store アプリ (Amphetamine 等) |
| choco | `choco/packages.txt` | Windows GUI アプリ (`#` 行はコメント) |

brew → mise へ移行したツール (bitwarden, gh 等) があるため、`update-tools.zsh` の
brew リストと mise の対象は対応関係を保って更新すること。

### dotmine サブモジュール

`dotmine/` は **private の別リポジトリ** (SSH キー、個人 gitconfig、ライセンス情報など、
公開できない個人設定の置き場)。setup.sh / setup.ps1 の末尾で `dotmine/setup.sh` が呼ばれる。
public な dotfiles 側のコミットに dotmine の内容を持ち込まないこと。
dotmine の変更が絡む場合はサブモジュール側でコミットしてからポインタを更新する。

どちらに置くかは **GitHub 上に出て困るか** で判断する。困るなら dotmine。

| 置き場 | 対象 | 例 |
|---|---|---|
| dotfiles (public) | 公開して困らない設定と、OSS ツールの導入手順 | brew / mise / choco のパッケージリスト、共通の zsh・git 設定、setup スクリプト本体、symlink 戦略 |
| dotmine (private) | 秘密情報・個人を特定する情報・組織固有の情報 | SSH 鍵と `known_hosts` / `authorized_keys`、aws / gcloud の認証を伴う設定、`.netrc`、氏名やメールを含む gitconfig、ライセンスキー、社内 tap の formula |

公開できない設定が要るときは、**実体を dotmine に置き、こちら側にはリンクや呼び出しだけを残す**
(既存の例: `files/.gitconfig` は `[include] path = ~/.gitconfig-mine` と書くだけで、実体は dotmine 側)。
逆に、公開して困らないものを dotmine に抱えない。両方に同じ設定を置いて二重管理しない。

**dotmine 側の規約はこちらとは別**。詳細は `dotmine/AGENTS.md` を参照 (コミット本文の言語が違う)。

### git SSH 署名 (macOS)

Claude Desktop 等 `SSH_AUTH_SOCK` が macOS 標準 agent に固定される環境でも署名が通るよう、
`files/bin/ssh-{keygen,add}-bitwarden.sh` wrapper で Bitwarden の socket を強制している。
`gpg.ssh.*` は `~` を展開しないため設定は絶対パスで書く (setup.sh が生成)。

### GUI アプリの PATH (macOS)

Dock 起動のアプリは launchd 既定 PATH (`/usr/local/bin` を含まない) を継承するため、
setup.sh が `sudo launchctl config user path` で `/usr/local/bin` を足す。

- `$HOME` 外のシステム領域 (`/private/var/db/com.apple.xpc.launchd/config/user.plist`) を
  書き換えるので **symlink 戦略の対象外**。sudo が必要 (`pmset` と同じ扱い) で、
  反映は次回 boot 時 (setup.sh は再起動しない)
- **値を固定文字列で上書きしない。** 現在の登録値を読み、`/usr/local/bin` を含まなければ
  先頭に足して再登録し、含んでいれば何もしない (他の目的で登録されたパスを消さないため)。
  未登録時の基準値は `getconf PATH`
- 登録値の読み出しはキー名 `PathEnvironmentVariable` を直接見て、失敗したら `plutil -p` の
  出力から拾うフォールバックを持つ

3 パターンの挙動と却下した代替案は [README.md](README.md) を参照。

### スリープ管理 (macOS)

蓋閉じ抑止は `pmset disablesleep` ではなく Amphetamine (mas 導入) に委譲する方針。
pmset は idle sleep のスケジュールのみ管理 (バッテリ 60 分 / 電源接続時なし)。
詳細な運用と Amphetamine の設定値は [README.md](README.md) を参照。

## 規約

- コミットメッセージは Conventional Commits 形式 (`feat:` / `chore:` 等)、本文は英語
- コミットメッセージの先頭に、内容を表す絵文字を 1 つ付ける (例: `✨ feat: add launchd PATH configuration`、
  `🐛 fix: skip brew upgrade confirmation prompt`)。絵文字はショートコード (`:sparkles:`) ではなく実体で書く
- スクリプト内コメントは日本語。「なぜそうするか」(例: cask/formula 名の衝突、`~` 非展開) を書く
- パッケージリスト (`*.txt`) はアルファベット順を維持する
