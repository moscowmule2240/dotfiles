#!/bin/bash
# 変わった bash のスクリプトを、bash 3.2 (macOS の /bin/bash と同じ版) の構文検査・bash 4 以降の構文の grep と
# ShellCheck で検査する (行頭を「# shellcheck」にすると指示として読まれる)。macOS で動かすスクリプトが、Linux や Windows で書かれても壊れないようにするため。
#
# 使い方 (検査するリポジトリの中で流す):
#   check.sh --all              追跡しているファイルを全部検査する
#   check.sh <base> <head>      <base>...<head> (merge-base から) で変わったファイルを検査する。作業ツリーは <head>
# 環境変数:
#   BASH32         bash 3.2 の実行ファイル。空なら Docker で固定したイメージを使う
#   SHELLCHECK     shellcheck の実行ファイル。空なら PATH の shellcheck
#   GITHUB_ACTIONS true なら GitHub Actions の注釈の形で出す
# 目印:
#   先頭 10 行の中の「# bash-compat: linux-only」  Linux の上でだけ動く。bash 3.2 の検査と grep を飛ばす
#   行末の「# bash-compat: ignore」                その行だけ bash 4 以降の構文の grep を飛ばす
# exit: 0 = 指摘なし、1 = 指摘あり、2 = 検査できない
# bash 3.2 で動かすため、連想配列・mapfile は使わない。
set -u

IMAGE='bash:3.2.57@sha256:44900632c47e54937a3c2d7de2b4d05af7aee6d269c71c3116204842ee26101c'
MARK_LINUX_ONLY='# bash-compat: linux-only'
# 拡張子の無いスクリプトを shebang で拾う。env -S の形も拾う (外して黙って検査から逃げられないように)
SHEBANG_RE='^#![[:space:]]*(/usr/bin/env[[:space:]]+(-S[[:space:]]+)?)?(/[^[:space:]]*/)?(ba)?sh([[:space:]]|$)'

# bash 3.2 の bash -n は通るが、3.2 で実行すると壊れる・結果が変わる構文。正規表現と説明を並べる。
# case の ;& や |&、&>> は bash 3.2 の bash -n が構文エラーにするのでここには入れない
BASH4_RE=()
BASH4_LABEL=()
add_bash4() { BASH4_RE+=("$1"); BASH4_LABEL+=("$2"); }
add_bash4 '(^|[;&|[:space:](])(declare|local|typeset)[[:space:]]+-[a-zA-Z]*[Aglnu]' 'declare・local・typeset の -A・-g・-l・-n・-u' # bash-compat: ignore
add_bash4 '(^|[;&|[:space:]])local[[:space:]]+-([[:space:];]|$)' 'local -' # bash-compat: ignore
add_bash4 '\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(\^|,)' '${var,,}・${var^^} の大文字・小文字の変換' # bash-compat: ignore
add_bash4 '\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?@[A-Za-z]' '${var@X} の変換' # bash-compat: ignore
add_bash4 '\$\{[A-Za-z_][A-Za-z0-9_]*:[^}:]*:[[:space:]]*-[0-9]' '${var:N:-M} の負の長さ' # bash-compat: ignore
add_bash4 '\$\{[A-Za-z_][A-Za-z0-9_]*\[-[0-9]+\]' '${a[-1]} の負の添字' # bash-compat: ignore
add_bash4 '(^|[^[:alnum:]_])(mapfile|readarray)([^[:alnum:]_]|$)' 'mapfile・readarray' # bash-compat: ignore
add_bash4 '(^|[;&|[:space:]])read([[:space:]]+-[a-zA-Z]+)*[[:space:]]+-[a-zA-Z]*N' 'read -N' # bash-compat: ignore
add_bash4 '\{[A-Za-z_][A-Za-z0-9_]*\}[<>]' '{fd}> の名前付きの fd' # bash-compat: ignore
add_bash4 '%\([^)]*\)T' "printf の %(…)T" # bash-compat: ignore
add_bash4 'shopt[[:space:]]+-s[[:space:]].*(globstar|lastpipe|autocd|checkjobs|direxpand|dirspell|globasciiranges|inherit_errexit|localvar_inherit|assoc_expand_once)' 'shopt -s の bash 4 以降の項目' # bash-compat: ignore
add_bash4 '(^|[;&|[:space:]])wait[[:space:]]+-[a-zA-Z]*n' 'wait -n' # bash-compat: ignore
add_bash4 '(\[\[?|(^|[^[:alnum:]_])test)[[:space:]]+-v[[:space:]]' '-v の変数の存在の検査' # bash-compat: ignore
add_bash4 '(^|[^[:alnum:]_])(EPOCHSECONDS|EPOCHREALTIME|BASH_ARGV0)([^[:alnum:]_]|$)' 'EPOCHSECONDS・EPOCHREALTIME・BASH_ARGV0' # bash-compat: ignore
add_bash4 '(^|[;&|[:space:]])coproc([[:space:]]|$)' 'coproc' # bash-compat: ignore
add_bash4 '\{-?[0-9A-Za-z]+\.\.-?[0-9A-Za-z]+\.\.-?[0-9]+\}' '{1..10..2} の刻み付きの展開' # bash-compat: ignore
add_bash4 '\{-?0[0-9]+\.\.-?[0-9]+\}' '{01..03} の 0 埋めの展開' # bash-compat: ignore

die() {
  echo "error: $*" >&2
  exit 2
}

# GitHub Actions の注釈の値のエスケープ。値は % と改行、プロパティはさらに : と ,
esc_data() {
  s=$1
  s=${s//"%"/%25}
  s=${s//$'\r'/%0D}
  s=${s//$'\n'/%0A}
  printf '%s' "$s"
}
esc_prop() {
  s=$(esc_data "$1")
  s=${s//":"/%3A}
  s=${s//","/%2C}
  printf '%s' "$s"
}

gha=false
[ "${GITHUB_ACTIONS:-}" = true ] && gha=true
findings=0

# 指摘を 1 件出す。$1 = ファイル、$2 = 行 (不明なら空)、$3 = 種類、$4 = 内容
report() {
  findings=$((findings + 1))
  if $gha; then
    if [ -n "$2" ]; then
      printf '::error file=%s,line=%s::%s\n' "$(esc_prop "$1")" "$2" "$(esc_data "$3: $4")"
    else
      printf '::error file=%s::%s\n' "$(esc_prop "$1")" "$(esc_data "$3: $4")"
    fi
  elif [ -n "$2" ]; then
    printf '%s:%s: %s: %s\n' "$1" "$2" "$3" "$4"
  else
    printf '%s: %s: %s\n' "$1" "$3" "$4"
  fi
}

# 警告を 1 件出す (exit には効かない)。$1 = ファイル、$2 = 行 (不明なら空)、$3 = 内容
warn() {
  if $gha; then
    if [ -n "$2" ]; then
      printf '::warning file=%s,line=%s::%s\n' "$(esc_prop "$1")" "$2" "$(esc_data "$3")"
    else
      printf '::warning file=%s::%s\n' "$(esc_prop "$1")" "$(esc_data "$3")"
    fi
  elif [ -n "$2" ]; then
    printf '%s:%s: warning: %s\n' "$1" "$2" "$3"
  else
    printf '%s: warning: %s\n' "$1" "$3"
  fi
}

notice() {
  if $gha; then
    printf '::notice::%s\n' "$(esc_data "$1")"
  else
    printf '%s\n' "$1"
  fi
}

# パスと 1 行目から、検査の対象かを決める。zsh の shebang は拡張子が .sh でも外す
is_target_by() {
  case "$2" in '#!'*zsh*) return 1 ;; esac
  case "$1" in *.sh | *.bash) return 0 ;; esac
  printf '%s\n' "$2" | grep -Eq "$SHEBANG_RE"
}

first_line_of() {
  first=''
  IFS= read -r first < "$1" || true
  printf '%s' "$first"
}

# 作業ツリーのファイルが検査の対象か。symlink は指す先の側で検査するので外す
is_target() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  is_target_by "$1" "$(first_line_of "$1")"
}

run_bash32() {
  if [ -n "${BASH32:-}" ]; then
    "$BASH32" "$@"
  else
    docker run --rm -v "$PWD:/w:ro" -w /w "$IMAGE" bash "$@"
  fi
}

# ---- 引数と前提の確かめ
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die "git のリポジトリの中で流す"
cd "$toplevel" || die "$toplevel に移れない"

mode='all'
base=''
head=''
if [ "$#" = 1 ] && [ "$1" = --all ]; then
  :
elif [ "$#" = 2 ]; then
  base=$1
  head=$2
  git cat-file -e "$head^{commit}" 2>/dev/null || die "head ($head) が commit ではない"
  [ "$(git rev-parse HEAD)" = "$(git rev-parse "$head^{commit}")" ] || die "作業ツリーの HEAD が head ($head) と違う"
  if printf '%s' "$base" | grep -Eq '^0+$' || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
    notice "比べる元が無いので全部を検査する (base: $base)"
  else
    mode='diff'
    merge_base=$(git merge-base "$base" "$head") || die "$base と $head の merge-base が無い"
  fi
else
  die "使い方: check.sh --all | check.sh <base> <head>"
fi

tmp=$(mktemp -d) || die "一時ディレクトリーを作れない"
trap 'rm -rf "$tmp"' EXIT

# 版は stdout だけで判定する。Docker の初回はイメージの取得のメッセージが stderr に出るため
# shellcheck disable=SC2016  # $BASH_VERSION は bash 3.2 の側で展開する
bash_version=$(run_bash32 -c 'echo "$BASH_VERSION"' 2> "$tmp/bash32-err") || die "bash 3.2 を起動できない: $(cat "$tmp/bash32-err")"
case "$bash_version" in 3.2.*) ;; *) die "BASH32 が bash 3.2 ではない ($bash_version)" ;; esac
shellcheck_cmd=${SHELLCHECK:-shellcheck}
shellcheck_version=$("$shellcheck_cmd" --version 2>&1) || die "shellcheck を起動できない: $shellcheck_version"
notice "bash $bash_version / shellcheck $(printf '%s\n' "$shellcheck_version" | sed -n 's/^version: //p')"

# ---- 対象の一覧 (git の rc を確かめるため、いったんファイルに書く)
if [ "$mode" = all ]; then
  git ls-files -z > "$tmp/list" || die "git ls-files が失敗した"
else
  git diff -z --name-only --no-ext-diff --diff-filter=ACMRT -M "$merge_base" "$head" > "$tmp/list" || die "git diff が失敗した"
fi

: > "$tmp/targets"
while IFS= read -r -d '' f; do
  if is_target "$f"; then
    printf '%s\0' "$f" >> "$tmp/targets"
  fi
done < "$tmp/list"

# ---- 検査を弱める変更の警告 (差分のときだけ)
if [ "$mode" = diff ]; then
  # 設定のファイル。改名は消したものと足したものの両方で見る
  git diff -z --name-only --no-ext-diff --no-renames "$merge_base" "$head" > "$tmp/all-changed" || die "git diff が失敗した"
  while IFS= read -r -d '' f; do
    case "$f" in
      .github/workflows/* | ci/bash-compat/* | .shellcheckrc | shellcheckrc | */.shellcheckrc | */shellcheckrc)
        warn "$f" '' "CI の設定が変わった。結果を信用せず差分を見ること"
        ;;
    esac
  done < "$tmp/all-changed"

  # base では対象だったのに、head では対象でなくなったファイル (.zsh への改名・zsh の shebang など)
  git diff -z --name-status --no-ext-diff --diff-filter=MRT -M "$merge_base" "$head" > "$tmp/status" || die "git diff が失敗した"
  while IFS= read -r -d '' st; do
    IFS= read -r -d '' old || break
    new=$old
    case "$st" in R*) IFS= read -r -d '' new || break ;; esac
    old_first=$(git show "$merge_base:$old" 2>/dev/null | sed -n '1p')
    if is_target_by "$old" "$old_first" && ! is_target "$new"; then
      warn "$old" '' "検査の対象から外れた ($new)。結果を信用せず差分を見ること"
    fi
  done < "$tmp/status"

  # 足した行の目印と shellcheck の disable
  while IFS= read -r -d '' f; do
    git diff -U0 --no-color --no-ext-diff "$merge_base" "$head" -- "$f" > "$tmp/hunks" || die "git diff が失敗した"
    line=0
    while IFS= read -r l; do
      case "$l" in
        '@@ '*)
          line=$(printf '%s\n' "$l" | sed -n 's/^@@ -[0-9,]* +\([0-9]*\).*/\1/p')
          ;;
        '+++'*) ;;
        '+'*)
          case "$l" in
            *'bash-compat: linux-only'* | *'bash-compat: ignore'* | *'shellcheck disable'*)
              warn "$f" "$line" "検査を外す目印を足した。結果を信用せず差分を見ること"
              ;;
          esac
          line=$((line + 1))
          ;;
      esac
    done < "$tmp/hunks"
  done < "$tmp/targets"
fi

if [ ! -s "$tmp/targets" ]; then
  notice "対象なし"
  exit 0
fi

# ---- bash 3.2 の bash -n と bash 4 以降の構文の grep (Linux 専用の目印のあるファイルは飛ばす)
: > "$tmp/bash32-targets"
while IFS= read -r -d '' f; do
  if sed -n '1,10p' < "$f" | grep -qF -- "$MARK_LINUX_ONLY"; then
    continue
  fi
  printf '%s\0' "$f" >> "$tmp/bash32-targets"

  i=0
  while [ "$i" -lt "${#BASH4_RE[@]}" ]; do
    grep -nE -- "${BASH4_RE[$i]}" < "$f" | grep -Ev '^[0-9]+:[[:space:]]*#|# bash-compat: ignore[[:space:]]*$' > "$tmp/hits"
    while IFS= read -r hit; do
      report "$f" "${hit%%:*}" bash4-syntax "${BASH4_LABEL[$i]} (bash 3.2 では動かない)"
    done < "$tmp/hits"
    i=$((i + 1))
  done
done < "$tmp/targets"

# bash 3.2 の起動は 1 回にまとめ、ファイルごとに「名前・終了コード・出力」を NUL で区切って返させる
if [ -s "$tmp/bash32-targets" ]; then
  args=()
  while IFS= read -r -d '' f; do
    args+=("$f")
  done < "$tmp/bash32-targets"
  # shellcheck disable=SC2016  # 中の $ は bash 3.2 の側で展開する
  run_bash32 -c 'for f do o=$("$BASH" -n -- "$f" 2>&1); printf "%s\0%s\0%s\0" "$f" "$?" "$o"; done' bash32 "${args[@]}" > "$tmp/bash32-out" ||
    die "bash 3.2 での検査が途中で失敗した"
  while IFS= read -r -d '' f && IFS= read -r -d '' code && IFS= read -r -d '' o; do
    [ "$code" = 0 ] && continue
    reported=false
    while IFS= read -r l; do
      rest=${l#"$f: line "}
      [ "$rest" = "$l" ] && continue
      n=${rest%%:*}
      msg=${rest#*: }
      # 2 行目は問題の行そのものの引用なので飛ばす
      case "$msg" in '`'*) continue ;; esac
      report "$f" "$n" bash32 "$msg"
      reported=true
    done <<EOF
$o
EOF
    $reported || report "$f" '' bash32 "$o"
  done < "$tmp/bash32-out"
fi

# ---- shellcheck (Linux 専用の目印のあるファイルも当てる)
while IFS= read -r -d '' f; do
  shell_opt=()
  case "$(first_line_of "$f")" in '#!'*) ;; *) shell_opt=(-s bash) ;; esac
  "$shellcheck_cmd" -S warning -f gcc ${shell_opt[@]+"${shell_opt[@]}"} -- "$f" > "$tmp/sc" 2>&1
  code=$?
  [ "$code" -le 1 ] || die "shellcheck が $f で失敗した: $(cat "$tmp/sc")"
  [ "$code" = 0 ] && continue
  reported=false
  while IFS= read -r l; do
    rest=${l#"$f:"}
    [ "$rest" = "$l" ] && continue
    n=${rest%%:*}
    msg=${rest#*:*: }
    report "$f" "$n" shellcheck "$msg"
    reported=true
  done < "$tmp/sc"
  $reported || report "$f" '' shellcheck "$(cat "$tmp/sc")"
done < "$tmp/targets"

[ "$findings" = 0 ] || exit 1
exit 0
