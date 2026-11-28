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
update-tools() (
  emulate -L zsh
  setopt extendedglob

  # 多重同時実行による fix-cask (rm -rf) と brew upgrade の競合を防ぐ。
  # zsystem flock は POSIX fcntl(2) ロックを使うため、関数全体をサブシェル (...) で実行して
  # 対話シェル本体に lock_fd を残さず、Ctrl-Z (SIGTSTP) 時の fork によるロック喪失や同一 PID 再入を防ぐ。
  # プロセスが強制終了してもカーネルがロックを解放するため stale lock は残らない。
  # キャッシュ掃除で消されにくい state 配下に置き、ロックファイル自体は削除しない
  # (削除するとロック中に別 inode が作られて排他が破れる)。
  local lock_dir="${XDG_STATE_HOME:-$HOME/.local/state}"
  local lock_file="$lock_dir/update-tools.lock"
  local lock_fd=""
  if ! zmodload zsh/system 2>/dev/null; then
    print -u2 "update-tools: failed to load zsh/system"
    return 1
  fi
  if ! mkdir -p "$lock_dir" || ! : >> "$lock_file"; then
    print -u2 -r -- "update-tools: failed to prepare lock file: $lock_file"
    return 1
  fi

  local rc=0
  {
    # -t 0.1 はロック競合時に status 2、open/fcntl エラー時に status 1 を返す (zshmodules(1) の仕様)。
    local flock_rc=0
    zsystem flock -t 0.1 -f lock_fd "$lock_file" || flock_rc=$?
    if (( flock_rc == 2 )); then
      print -u2 -r -- "update-tools: another update-tools is already running ($lock_file)"
      return 1
    elif (( flock_rc != 0 )); then
      print -u2 -r -- "update-tools: failed to acquire lock ($lock_file; exit $flock_rc)"
      return 1
    fi

    brew update || rc=1
    # 既に上で brew update を流しているため、以降の brew 呼び出しでは自動更新を止める。
    # 正常時は _cask-app-ahead-fetch のスナップショットと各 cask の upgrade 時のカタログが乖離するのを防ぐ。
    # brew update が一部 tap 等で失敗した場合も、rc=1 を残しつつ毎回同じ失敗を繰り返さずスナップショットを揃える。
    local -x HOMEBREW_NO_AUTO_UPDATE=1

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
    local c
    for c in "${casks[@]}"; do
      fix-cask "$c" || rc=1
    done

    # 自己更新で cask の最新版に追いついたアプリは upgrade から外す (外さないと同じ版か古い版で上書きされる)。
    # 先頭側の cask 更新に数分かかる間に後続アプリが自己更新する TOCTOU を狭めるため、
    # brew info の取得だけ最初に 1 回済ませ、更新が必要な cask ごとに upgrade 直前で Info.plist を読み直す。
    # brew upgrade が sudo パスワード等を端末から読めるよう、stdin をリダイレクトせず配列ループで回す。
    # 判定の取得そのものが失敗した回は cask の upgrade ごと飛ばし、終了コードにも載せる。
    local fetch_rc=0
    _cask-app-ahead-foreach update-tools _update-tools-upgrade-cask "${casks[@]}" || fetch_rc=$?
    if (( fetch_rc == 2 )); then
      print -u2 "update-tools: could not compare app versions with the casks; skipped brew upgrade --cask"
      rc=1
    elif (( fetch_rc != 0 )); then
      rc=1
    fi

    brew upgrade --yes --formula -- \
      htop \
      mise \
      opencode \
      zsh \
      zsh-completions \
      zsh-git-prompt || rc=1
    # mise 管理に移したもの (旧 brew formula / uv tool 相当)
    # --yes: 確認プロンプトを自動承諾して対話なしで進める
    mise upgrade --yes bitwarden gh mitmproxy || rc=1
    brew cleanup -s || rc=1

    # Antigravity の setup を流し直す (共有の設定とプラグインをそろえ直す)。何度流しても同じ結果になる作りで、実体は
    # private な dotmine 側にあり、dotmine が無いマシンでは飛ばす。実行ビットに頼らず bash で流す。
    # DOTFILES_ROOT は .zsh_aliases が決める。読み込まれていないシェルでは黙って飛ばさずに知らせる。
    # setup が直した後の状態を、下の確認で見る (先に確かめると、直る前の警告が出て紛らわしい)。
    if [[ -z $DOTFILES_ROOT ]]; then
      print -u2 "update-tools: DOTFILES_ROOT is not set; skipped the Antigravity setup"
      rc=1
    elif [[ -f ${DOTFILES_ROOT}/dotmine/antigravity/setup.sh ]]; then
      bash "${DOTFILES_ROOT}/dotmine/antigravity/setup.sh" || rc=1
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
          rc=1
        elif [[ -n $agy_root && ${agy_link:A:h:h} != $agy_root ]]; then
          print -u2 "update-tools: ~/.gemini/config/$agy_shared points outside the shared folder (${agy_link:A}); Antigravity runs without the shared copy"
          rc=1
        fi
      done
      local agy_mcp=$HOME/.gemini/config/mcp_config.json agy_hooks_json=$HOME/.gemini/config/hooks.json
      if [[ -e $agy_mcp && -e $agy_hooks_json && ${agy_mcp:A:h} != ${agy_hooks_json:A:h} ]]; then
        print -u2 "update-tools: ~/.gemini/config/mcp_config.json and hooks.json point to different folders (${agy_mcp:A:h} / ${agy_hooks_json:A:h}); one of them was relinked"
        rc=1
      fi
    fi

    return $rc
  } always {
    [[ -n $lock_fd ]] && zsystem flock -u "$lock_fd" 2>/dev/null
  }
)

# brew info から更新判定に必要な cask 情報を NUL 区切り (1 cask あたり 6 フィールド) で抽出する (内部用)
# 出力は status / names / full_token / installed_base / latest / app の各末尾に \0 を付けた列。
# 改行や制御文字を含むメタデータによる行注入・列ずれと、空白区切りによる空フィールドの潰れをまとめて防ぐ。
# .app を持たない CLI 専用 cask でも outdated を落とさないよう、app が無いときは空文字を出す。
_cask-app-ahead-fetch() {
  emulate -L zsh
  local caller=$1
  shift
  if (( $# == 0 )); then
    print -u2 -r -- "usage: $caller <cask>..."
    return 1
  fi
  local info
  if ! info=$(brew info --json=v2 --cask -- "$@"); then
    print -u2 -r -- "$caller: brew info failed"
    return 1
  fi
  if ! printf '%s' "$info" | jq -j '
    .casks[]
    | (if .installed == null then "missing"
       elif .installed != .version then "outdated"
       elif .version == "latest" then "latest"
       else empty end) as $status
    | ([.token] + (([.full_token] + (.old_tokens // [])) - [.token]) | join(",")) as $names
    | ((.installed // "") | split(",")[0]) as $installed_base
    | ((.version // "") | split(",")[0]) as $latest
    | ([ .artifacts[] | objects | select(.app)
         | (.target // (.app
            | (if (.[1] | type) == "object" and .[1].target then .[1].target else .[0] end)
            | if startswith("/") or startswith("~") then . else "/Applications/" + . end)) ]
       + [ .artifacts[] | objects | .uninstall | arrays | .[] | objects | .delete // empty
         | (if type == "array" then .[] else . end)
         | strings | select(endswith(".app")) ]
       | .[0] // "") as $app
    | [$status, $names, .full_token, $installed_base, $latest, $app]
    | map(tostring + "\u0000") | add'; then
    print -u2 -r -- "$caller: jq failed to read the brew info output"
    return 1
  fi
  return 0
}

# _cask-app-ahead-fetch の NUL 区切りストリームを検証し、1 cask ごとに callback を呼ぶ (内部用)
# fetch またはストリーム形式の失敗は 2、callback が 1 件でも失敗したら 1、全件成功なら 0 を返す。
_cask-app-ahead-foreach() {
  emulate -L zsh
  local caller=$1 callback=$2
  shift 2
  local raw
  raw=$(_cask-app-ahead-fetch "$caller" "$@") || return 2
  [[ -n $raw ]] || return 0

  local -a fields=("${(@0)raw}")
  if (( ${#fields} < 7 || (${#fields} - 1) % 6 != 0 )) || [[ -n ${fields[-1]} ]]; then
    print -u2 -r -- "$caller: malformed cask metadata stream"
    return 2
  fi

  local i cb_rc=0
  for (( i = 1; i + 5 <= ${#fields}; i += 6 )); do
    "$callback" "$caller" \
      "${fields[i]}" "${fields[i+1]}" "${fields[i+2]}" \
      "${fields[i+3]}" "${fields[i+4]}" "${fields[i+5]}" || cb_rc=1
  done
  return $cb_rc
}

# update-tools の cask 1 件分の更新処理 (内部用)
_update-tools-upgrade-cask() {
  emulate -L zsh
  local caller=$1 cask_status=$2 names=$3 full_token=$4 installed_base=$5 latest=$6 app=$7
  local current
  case "$cask_status" in
    missing)
      print -u2 -r -- "$caller: cask '${names%%,*}' is not installed"
      return 1
      ;;
    latest)
      brew upgrade --yes --cask -- "$full_token"
      ;;
    outdated)
      if current=$(_cask-app-ahead-check "$caller" "${names%%,*}" "$installed_base" "$latest" "$app"); then
        print -r -- "$caller: skip ${names%%,*} (app $current is already at or ahead of cask $latest)"
        return 0
      else
        brew upgrade --yes --cask -- "$full_token"
      fi
      ;;
    *)
      print -u2 -r -- "$caller: unexpected cask status '$cask_status' for '${names%%,*}'"
      return 1
      ;;
  esac
}

# ドット区切りの非負整数列 2 つを全桁 10 進で比較し、REPLY に 1 ($1 > $2) / 0 ($1 == $2) / -1 ($1 < $2) を入れる (内部用)
# 各桁の先頭 0 を除いた桁数で比べ、同じ桁数なら [[ > ]] (zsh ではロケールに依らず ASCII 順) で比べることで、
# 0 埋めの 10 進比較 (2.11.09 > 2.11.0 等) と 64 ビット整数を超える桁の比較を両立する。
_cask-app-ahead-cmp() {
  emulate -L zsh
  setopt extendedglob
  local -a a_parts=(${(s:.:)1}) b_parts=(${(s:.:)2})
  local max_len=$(( ${#a_parts} > ${#b_parts} ? ${#a_parts} : ${#b_parts} ))
  local i a_part b_part
  for (( i = 1; i <= max_len; i++ )); do
    a_part=${${a_parts[i]:-0}##0#}
    b_part=${${b_parts[i]:-0}##0#}
    a_part=${a_part:-0}
    b_part=${b_part:-0}
    if (( ${#a_part} != ${#b_part} )); then
      (( ${#a_part} > ${#b_part} )) && REPLY=1 || REPLY=-1
      return 0
    elif [[ $a_part != $b_part ]]; then
      [[ $a_part > $b_part ]] && REPLY=1 || REPLY=-1
      return 0
    fi
  done
  REPLY=0
  return 0
}

# 1 件の outdated cask について、現時点のアプリ本体が cask の版に追いついている・追い越しているか判定する (内部用)
# 追いついている場合はアプリの版を stdout に出して 0 を返す。upgrade すべき・判定不能なら 1 を返す。
_cask-app-ahead-check() {
  emulate -L zsh
  setopt extendedglob
  local caller=$1 name=$2 installed_base=$3 latest=$4 app=$5
  # .app を持たない CLI 専用 cask は判定対象外として brew に任せる
  [[ -n $app ]] || return 1

  # uninstall の delete や target は ~/ 始まりで書かれることがある
  local plist="${app/#\~\//$HOME/}/Contents/Info.plist"
  if [[ ! -f $plist ]]; then
    print -u2 -r -- "$caller: $name: $plist not found; left to brew"
    return 1
  fi
  local current
  if ! current=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null) || [[ -z ${current//[[:space:]]/} ]]; then
    print -u2 -r -- "$caller: $name: CFBundleShortVersionString not found in $plist; left to brew"
    return 1
  fi
  if [[ $current != <->(.<->)# || $latest != <->(.<->)# ]]; then
    print -u2 -r -- "$caller: $name: non-numeric version ($current / $latest); left to brew"
    return 1
  fi

  local REPLY
  _cask-app-ahead-cmp "$current" "$latest"
  (( REPLY < 0 )) && return 1
  # installed と version のカンマ前が同じ場合 (例: 4.99.0,245800 -> 4.99.0,245822) はカンマ以降のビルド番号だけの更新。
  # アプリが同じ版のまま (current == latest) なら自己更新していない旧ビルドの可能性があるため skip せず brew に任せる。
  # アプリが先の版へ自己更新済み (current > latest) なら引き続き skip して巻き戻しを防ぐ。
  if (( REPLY == 0 )) && [[ $installed_base == <->(.<->)# ]]; then
    _cask-app-ahead-cmp "$installed_base" "$latest"
    (( REPLY == 0 )) && return 1
  fi

  print -r -- "$current"
  return 0
}

# cask-app-ahead の 1 件分の出力処理 (内部用)
_cask-app-ahead-print() {
  emulate -L zsh
  local caller=$1 cask_status=$2 names=$3 full_token=$4 installed_base=$5 latest=$6 app=$7
  [[ $cask_status == outdated ]] || return 0
  local current
  if current=$(_cask-app-ahead-check "$caller" "${names%%,*}" "$installed_base" "$latest" "$app"); then
    print -r -- "$names"$'\t'"$current"$'\t'"$latest"
  fi
  return 0
}

# 自己更新でアプリ本体が cask の最新版に追いついている・追い越している cask を列挙する
# brew は auto_updates な cask の新旧を Caskroom に記録した版 (brew で最後に入れた版) と cask の版だけで判定し、
# /Applications のアプリが自分で上がった版を見ない。名前を指定した upgrade は greedy 扱いなので、記録が古いだけで
# cask の版 (= アプリより古いことがある) で上書きされる。onedrive は自己更新した 26.204 が 26.198 に戻され、
# 新しい版が移行した同期 DB を読めずに起動しなくなった (2026-11-13 に発生)。
# アプリの CFBundleShortVersionString と cask の版 (カンマより前) をドット区切りの各桁で 10 進数値として比べる。片方にしか無い桁は 0 とみなす。
# 桁数の違う版で、アプリ側に無い桁を「同じ」とみなすと、pycharm の 2026.3 → 2026.3.1 や 2026.3 → 2026.3.0.2 のような前に進む upgrade まで止まる。
# zsh の is-at-least は比較対象の末尾に 0 を 1 桁しか補わないため、アプリ側が 2 桁以上短く、アプリ側に無い最初の桁が 0 のとき (2026.3 と 2026.3.0.2 など)、
# 残りの桁を見ずに追いついていると誤判定する。そのため is-at-least を使わず全桁を自前で比べる。
# 0 とみなす代わりに、アプリの版が build の桁を持たない cask では build の違いを見分けられない。onedrive はアプリが 26.204.1019、
# cask が 26.204.1019.0007 のように cask だけが build の桁を持つので、cask が同じ版に追いつくと同じ版の入れ直しになり、
# アプリが同じ版の新しい build (例: .0009) に上がっていたときは古い build へ戻る。版そのものの巻き戻し (26.204 → 26.198) は防げる。
# また installed と version のカンマ前が同じリビルド (例: 4.99.0,245800 → 4.99.0,245822) では、アプリが同じ版 (4.99.0) のときは
# ホットフィックスの取りこぼしを防ぐため skip せず brew に任せ、アプリが先の版へ進んでいるときだけ skip する。
# 数字とドット以外を含む版 (8.0.47.CE 等) は判定せず stderr へ知らせて brew の判定に任せる (version :latest は別経路で brew に渡す)。
# アプリの場所は Homebrew が解決済みの app artifact の target を優先し、無ければ app 定義、さらに無ければ pkg の cask として
# uninstall の delete にある .app から取る。.app が複数ある cask は最初の 1 つだけを見る。
# 場所を解決したのにアプリが無い・CFBundleShortVersionString を読めない・版が数値でないときは、判定せずに stderr へ知らせる。
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
  _cask-app-ahead-foreach cask-app-ahead _cask-app-ahead-print "$@" || return 1
  return 0
}
