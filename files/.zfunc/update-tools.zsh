#!/usr/bin/env zsh

# よく使うソフトウェアをまとめて最新化する
# onedrive のように cask 名と formula 名が衝突するパッケージがあるので、
# --cask / --formula を明示して呼び分ける。
# brew 6.0 以降は upgrade 前に [y/n] を聞く ask mode が既定なので --yes で無効化する。
# 環境変数 HOMEBREW_NO_ASK でも消せるが、それだと手打ちの brew upgrade まで
# 無確認になるため、対象を明示しているこの関数の中だけに閉じる。
# cask を名前で列挙する限り --greedy は不要 (Cask::Upgrade.outdated_casks は
# 名前指定時に greedy: true 固定で判定するため、auto_updates な cask も対象になる)。
# --greedy が要るのは対象を指定せず brew upgrade する場合。
update-tools() {
  brew update
  local -a casks=(
    antigravity-cli
    antigravity-ide
    bitwarden
    claude
    claude-code@latest
    comet
    docker-desktop
    google-chrome
    iterm2
    mysqlworkbench
    onedrive
    pycharm
    typeless
    visual-studio-code
  )
  # 自己更新で brew の symlink を実ファイルに潰す cask (antigravity-cli 等) を upgrade の前に直す。
  # 潰れたまま upgrade すると旧版の削除後に新版のリンクで衝突して落ち、Caskroom が
  # .metadata だけの抜け殻になって以後 "Cask ... is not installed" になる。
  # fix-cask は正常な cask には何もしないので、リストごと通して漏れを防ぐ。
  local c; for c in $casks; do fix-cask "$c"; done
  brew upgrade --yes --cask $casks
  brew upgrade --yes --formula \
    htop \
    mise \
    zsh \
    zsh-completions \
    zsh-git-prompt
  # mise 管理に移したもの (旧 brew formula / uv tool 相当)
  # --yes: 確認プロンプトを自動承諾して対話なしで進める
  mise upgrade --yes bitwarden gh mitmproxy
  brew cleanup -s

  # Antigravity の setup を流し直す (共有の設定とプラグインをそろえ直す)。何度流しても同じ結果になる作りで、実体は
  # private な dotmine 側にあり、dotmine が無いマシンでは飛ばす。実行ビットに頼らず bash で流す。
  # DOTFILES_ROOT は .zsh_aliases が決める。読み込まれていないシェルでは黙って飛ばさずに知らせる。
  # setup が直した後の状態を、下の確認で見る (先に確かめると、直る前の警告が出て紛らわしい)。
  if [[ -z $DOTFILES_ROOT ]]; then
    print -u2 "update-tools: DOTFILES_ROOT is not set; skipped the Antigravity setup"
  elif [[ -f ${DOTFILES_ROOT}/dotmine/antigravity/setup.sh ]]; then
    bash "${DOTFILES_ROOT}/dotmine/antigravity/setup.sh"
  fi

  # Antigravity の共有の設定の確認。~/.gemini/config の mcp_config.json と hooks.json は、~/.claude/hooks の実体と同じ
  # 共有の置き場にある実体への symlink で置く。クライアントの保存や agy mcp で実ファイルに置き換わったり、共有の置き場が
  # 見えなくなったり、別の場所を指すように張り替えられたりすると、Antigravity は共有の MCP の設定やフックなしで動き、
  # 何も知らせない (セッション開始のフックも hooks.json に登録されている) ので、ここで確かめる。
  # 共有の置き場は位置で照らす (置き場の名前をこのファイルに書かない): どちらも「~/.claude/hooks の実体の、親の親の下」にあり、
  # 2 つが同じフォルダーにそろっていること。両方とも同じ Drive の中の別のフォルダーへ張り替えられたときは気付けない。
  if (( $+commands[agy] )); then
    local agy_shared agy_root="" agy_hooks=$HOME/.claude/hooks
    [[ -L $agy_hooks ]] && agy_root=${agy_hooks:A:h:h}
    for agy_shared in mcp_config.json hooks.json; do
      local agy_link=$HOME/.gemini/config/$agy_shared
      if [[ ! -L $agy_link || ! -e $agy_link ]]; then
        print -u2 "update-tools: ~/.gemini/config/$agy_shared is missing or not a working symlink; Antigravity runs without the shared copy"
      elif [[ -n $agy_root && ${agy_link:A:h:h} != $agy_root ]]; then
        print -u2 "update-tools: ~/.gemini/config/$agy_shared points outside the shared folder (${agy_link:A}); Antigravity runs without the shared copy"
      fi
    done
    local agy_mcp=$HOME/.gemini/config/mcp_config.json agy_hooks_json=$HOME/.gemini/config/hooks.json
    if [[ -e $agy_mcp && -e $agy_hooks_json && ${agy_mcp:A:h} != ${agy_hooks_json:A:h} ]]; then
      print -u2 "update-tools: ~/.gemini/config/mcp_config.json and hooks.json point to different folders (${agy_mcp:A:h} / ${agy_hooks_json:A:h}); one of them was relinked"
    fi
  fi
}
