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
    t3-code
    typeless
    visual-studio-code
  )
  # 自己更新で brew の symlink を実ファイルに潰す cask (antigravity-cli 等) を upgrade の前に直す。
  # 潰れたまま upgrade すると旧版の削除後に新版のリンクで衝突して落ち、Caskroom が
  # .metadata だけの抜け殻になって以後 "Cask ... is not installed" になる。
  # fix-cask は正常な cask には何もしないので、リストごと通して漏れを防ぐ。
  local c; for c in $casks; do fix-cask "$c"; done
  # 自己更新で cask の最新版に追いついたアプリは upgrade から外す (外さないと同じ版か古い版で上書きされる)。
  # 判定そのものが失敗した回は cask の upgrade ごと飛ばす。黙って進むと、外すはずだった cask まで古い版で上書きしうるため
  # 判定の失敗は update-tools の終了コードにも載せる (長い出力の中の 1 行だけだと見落とすため)
  local ahead_list names name current latest cask_check=0
  if ahead_list=$(cask-app-ahead $casks); then
    while IFS=$'\t' read -r names current latest; do
      [[ -n $names ]] || continue
      print "update-tools: skip ${names%%,*} (app $current is already at or ahead of cask $latest)"
      # brew info は改名前の名前や tap 付きの名前で渡しても正式な token で返す。リストの書き方に合わせられるよう、
      # cask-app-ahead が並べた名前をすべて外す (正式な token だけで外すと、別の書き方の名前が残って upgrade される)
      for name in ${(s:,:)names}; do casks=(${casks:#${(b)name}}); done
    done <<< "$ahead_list"
    # 空のまま呼ぶと、名前を指定しない brew upgrade になって入っている cask がすべて対象になる
    (( ${#casks} )) && brew upgrade --yes --cask $casks
  else
    print -u2 "update-tools: could not compare app versions with the casks; skipped brew upgrade --cask"
    cask_check=1
  fi
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
  return $cask_check
}

# 自己更新でアプリ本体が cask の最新版に追いついている・追い越している cask を列挙する
# brew は auto_updates な cask の新旧を Caskroom に記録した版 (brew で最後に入れた版) と cask の版だけで判定し、
# /Applications のアプリが自分で上がった版を見ない。名前を指定した upgrade は greedy 扱いなので、記録が古いだけで
# cask の版 (= アプリより古いことがある) で上書きされる。onedrive は自己更新した 26.204 が 26.198 に戻され、
# 新しい版が移行した同期 DB を読めずに起動しなくなった (2026-11-13 に発生)。
# アプリの CFBundleShortVersionString と cask の版 (カンマより前) を zsh の is-at-least で比べる。片方にしか無い桁は 0 とみなす。
# 桁数の違う版で、アプリ側に無い桁を「同じ」とみなすと、pycharm の 2026.3 → 2026.3.1 のような前に進む upgrade まで止まる。
# 0 とみなす代わりに、アプリの版が build の桁を持たない cask では build の違いを見分けられない。onedrive はアプリが 26.204.1019、
# cask が 26.204.1019.0007 のように cask だけが build の桁を持つので、cask が同じ版に追いつくと同じ版の入れ直しになり、
# アプリが同じ版の新しい build (例: .0009) に上がっていたときは古い build へ戻る。版そのものの巻き戻し (26.204 → 26.198) は防げる。
# 数字とドット以外を含む版 (version :latest や 8.0.47.CE) は判定せず、brew の判定に任せる。
# アプリの場所は app artifact (target があればそちら) を優先し、無ければ pkg の cask として uninstall の delete にある .app から取る。
# app artifact の相対名は brew の既定の appdir (/Applications) に置かれる前提で解決する。.app が複数ある cask は最初の 1 つだけを見る。
# 場所を解決したのにアプリが無いとき (HOMEBREW_CASK_OPTS の --appdir で別の場所に入れているときなど) は、判定せずに知らせる。
# 見るのは brew が upgrade の対象にする cask (Caskroom の記録が cask の版と違うもの) だけにする。
# 記録が最新の cask は upgrade されないので、外す必要も知らせる必要もない。外した cask は Caskroom の記録が古いまま残るので、
# cask がアプリに追いつくまで、update-tools を流すたびに skip の行が出る。
#
# usage: cask-app-ahead <cask>...
#   追いついている cask を「cask の名前<TAB>アプリの版<TAB>cask の版」で 1 行ずつ出す。cask の名前は正式な token を先頭に、
#   tap 付きの名前と改名前の名前をカンマ区切りで続ける (渡された名前が正式な token とは限らないため)。
#   brew info か jq が失敗して判定できないときは 1 を返す (呼び出し側が、判定なしに upgrade へ進まないため)
cask-app-ahead() {
  emulate -L zsh
  setopt extendedglob
  autoload -Uz is-at-least
  local info rows
  if ! info=$(brew info --json=v2 --cask "$@"); then
    print -u2 "cask-app-ahead: brew info failed"
    return 1
  fi
  if ! rows=$(printf '%s' "$info" | jq -r '
    .casks[]
    | select(.installed != null and .installed != .version)
    | ([.token] + (([.full_token] + (.old_tokens // [])) - [.token]) | join(",")) as $names
    | (.version | split(",")[0]) as $latest
    | ([ .artifacts[] | .app // empty
         | (if (.[1] | type) == "object" and .[1].target then .[1].target else .[0] end)
         | if startswith("/") then . else "/Applications/" + . end ]
       + [ .artifacts[] | .uninstall // empty | .[] | .delete // empty
         | (if type == "array" then .[] else . end)
         | select(endswith(".app")) ]
       | .[0] // empty) as $app
    | [$names, $latest, $app] | @tsv'); then
    print -u2 "cask-app-ahead: jq failed to read the brew info output"
    return 1
  fi

  # ループの中で local を書き直すと、zsh は既にある変数の値を標準出力に出すので、ここでまとめて宣言する
  local names latest app plist current
  while IFS=$'\t' read -r names latest app; do
    [[ -n $names ]] || continue
    # uninstall の delete は ~ 始まりで書かれることがある
    plist="${app/#\~/$HOME}/Contents/Info.plist"
    if [[ ! -f $plist ]]; then
      print -u2 "cask-app-ahead: ${names%%,*}: $plist not found; left to brew"
      continue
    fi
    current=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null) || continue
    [[ $current == <->(.<->)# && $latest == <->(.<->)# ]] || continue

    # is-at-least は 0006 のような 0 埋めの桁も 10 進で比べる (2.11.09 > 2.11.0 を実測)
    is-at-least "$latest" "$current" && print -r -- "$names"$'\t'"$current"$'\t'"$latest"
  done <<< "$rows"
  return 0
}
