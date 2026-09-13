#!/usr/bin/env zsh

# 自己更新するアプリに壊された brew cask を検知して入れ直す
# antigravity-cli のように auto_updates で自分のバイナリを直接書き換える cask は、
# brew が $(brew --prefix)/bin に張った symlink を実ファイルで上書きしてしまう。
# その状態で brew upgrade すると旧版の Caskroom を消した後、新版の symlink を張る段で
# 「already a Binary」で衝突して落ち、Caskroom に .metadata だけ残る抜け殻になる。
# 抜け殻になると brew list には出るのに brew info は Not installed と言い、以後の
# upgrade は "Cask ... is not installed" で通らない (2026-09-13 に antigravity-cli で発生)。
# .app を丸ごと管理する cask (typeless 等) は自己更新しても symlink 構造が崩れないので
# この問題は起きない。binary artifact を持つ cask だけが対象。
#
# 検知するのは次の 2 つ。どちらかに該当すれば Caskroom と binary を消して brew install する。
#   (a) Caskroom/<cask> に .metadata しか無い      … upgrade が途中で落ちた後の状態
#   (b) binary の symlink が実ファイルになっている  … 自己更新に潰された、upgrade が落ちる前の状態
# (b) の段階で直せば upgrade が壊れないので、update-tools が upgrade の前にリストごと通す。
# 正常な cask には何もせず、出力もしない (リストで回したときに埋もれないため)。
# binary artifact を持たない cask は (a) だけ見る。
#
# usage: fix-cask [-n] <cask>
#   -n  検知結果だけ表示して rm も install もしない
fix-cask() {
  local dry_run=0
  if [ "$1" = "-n" ]; then dry_run=1; shift; fi
  if [ $# -eq 0 ]; then
    echo "usage: fix-cask [-n] <cask>" >&2
    return 1
  fi
  local cask=$1
  local info
  if ! info=$(brew info --cask "$cask" --json=v2 2>/dev/null); then
    echo "fix-cask: cask '$cask' が brew に無い" >&2
    return 1
  fi

  local prefix caskroom binary
  prefix=$(brew --prefix)
  caskroom="$prefix/Caskroom/$cask"
  # binary artifact の配置先 (brew が絶対パスで計算済み)。無い cask は空になる
  binary=$(printf '%s' "$info" | jq -r '.casks[0].artifacts[] | select(.binary) | .target // empty')

  local -a reasons
  # (a) Caskroom に .metadata しか残っていない
  if [ -d "$caskroom" ]; then
    local -a entries
    entries=("$caskroom"/*(ND))
    entries=(${entries:#*/.metadata})
    [ ${#entries} -eq 0 ] && reasons+=("Caskroom が .metadata だけの抜け殻: $caskroom")
  fi
  # (b) brew が張った symlink が実ファイルに置き換わっている
  if [ -n "$binary" ] && [ -e "$binary" ] && [ ! -L "$binary" ]; then
    reasons+=("binary が symlink ではなく実ファイル: $binary")
  fi

  [ ${#reasons} -eq 0 ] && return 0

  if [ $dry_run -eq 1 ]; then
    echo "fix-cask: $cask を入れ直す必要がある (dry-run、何もしない)"
  else
    echo "fix-cask: $cask を入れ直す"
  fi
  local r; for r in $reasons; do echo "  - $r"; done
  [ $dry_run -eq 1 ] && return 0

  rm -rf "$caskroom"
  # dangling になった symlink も消す。残すと brew install が「already a Binary」で落ちる
  if [ -n "$binary" ] && { [ -e "$binary" ] || [ -L "$binary" ]; }; then
    rm -f "$binary"
  fi
  brew install --cask "$cask"
  return $?
}
