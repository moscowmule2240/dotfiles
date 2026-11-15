#!/bin/bash
# 変更で足した行 (または --all で追跡している全ファイル) から、カタカナ語の語尾の長音符を
# 省いた表記を検出する。内閣告示「外来語の表記」・JIS Z 8301:2019 に合わせ、英語の語末が
# -er・-or・-ar の語の長音符を省略しない規則を機械で守るため。
#
# 使い方 (検査するリポジトリの中で流す):
#   check.sh --all              追跡しているファイルを全部検査する (手元用)
#   check.sh <base> <head>      <base>...<head> (merge-base から) の diff で足した行だけを検査する。作業ツリーは <head>
# 環境変数:
#   GITHUB_ACTIONS true なら GitHub Actions の注釈の形で出す
# 目印:
#   行のどこかの「katakana: ignore」  その行だけ検査を飛ばす
# exit: 0 = 指摘なし、1 = 指摘あり、2 = 検査できない
# bash 3.2 で動かすため、連想配列・mapfile は使わない。
set -u

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

# 指摘を 1 件出す。$1 = ファイル、$2 = 行、$3 = 省略形、$4 = 正しい表記
report() {
  findings=$((findings + 1))
  msg="$3 -> $4 (語尾の長音符を省略しない)"
  if $gha; then
    printf '::error file=%s,line=%s::%s\n' "$(esc_prop "$1")" "$2" "$(esc_data "$msg")"
  else
    printf '%s:%s: %s\n' "$1" "$2" "$msg"
  fi
}

# 作業ツリーのファイルが検査の対象か。symlink・空のファイル・バイナリのファイル・表そのものは外す
is_target() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  case "$1" in
    ci/katakana/words.tsv | ci/katakana/exceptions.txt) return 1 ;;
  esac
  [ -s "$1" ] || return 1
  LC_ALL=C grep -Iq . -- "$1"
}

script_dir=$(cd "$(dirname "$0")" && pwd) || die "スクリプトのディレクトリーを特定できない"
words_file="$script_dir/words.tsv"
exceptions_file="$script_dir/exceptions.txt"
[ -f "$words_file" ] || die "語の表 ($words_file) が無い"
[ -f "$exceptions_file" ] || die "例外の表 ($exceptions_file) が無い"

# ---- 引数と前提の確かめ
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die "git のリポジトリの中で流す"
cd "$toplevel" || die "$toplevel に移れない"

mode='all'
base=''
head=''
merge_base=''
if [ "$#" = 1 ] && [ "$1" = --all ]; then
  :
elif [ "$#" = 2 ]; then
  mode='diff'
  base=$1
  head=$2
  git cat-file -e "$head^{commit}" 2>/dev/null || die "head ($head) が commit ではない"
  [ "$(git rev-parse HEAD)" = "$(git rev-parse "$head^{commit}")" ] || die "作業ツリーの HEAD が head ($head) と違う"
  git cat-file -e "$base^{commit}" 2>/dev/null || die "base ($base) が commit ではない"
  merge_base=$(git merge-base "$base" "$head") || die "$base と $head の merge-base が無い"
else
  die "使い方: check.sh --all | check.sh <base> <head>"
fi

tmp=$(mktemp -d) || die "一時ディレクトリーを作れない"
trap 'rm -rf "$tmp"' EXIT

# ---- 対象の一覧と入力の組み立て
: > "$tmp/input"
files=()
if [ "$mode" = all ]; then
  git ls-files -z > "$tmp/list" || die "git ls-files が失敗した"
  while IFS= read -r -d '' f; do
    [ -e "$f" ] || [ -L "$f" ] || die "一覧にある $f が作業ツリーに無い"
    if is_target "$f"; then
      idx=${#files[@]}
      files+=("$f")
      printf 'F%s\t%s\n' "$idx" "$f" >> "$tmp/input"
    fi
  done < "$tmp/list"
else
  git diff -z --name-status --no-ext-diff --diff-filter=ACMRT -M "$merge_base" "$head" > "$tmp/status" || die "git diff が失敗した"
  while IFS= read -r -d '' st; do
    IFS= read -r -d '' old || break
    new=$old
    case "$st" in R* | C*) IFS= read -r -d '' new || break ;; esac
    [ -e "$new" ] || [ -L "$new" ] || die "一覧にある $new が作業ツリーに無い"
    is_target "$new" || continue
    idx=${#files[@]}
    files+=("$new")
    printf 'F%s\n' "$idx" >> "$tmp/input"
    git --literal-pathspecs diff -U0 -a -M --no-textconv --no-color --no-ext-diff "$merge_base" "$head" -- "$old" "$new" >> "$tmp/input" ||
      die "git diff が失敗した"
  done < "$tmp/status"
fi

if [ ! -s "$tmp/input" ]; then
  exit 0
fi

# ---- 出現ごとの照合 (LC_ALL=C でバイト列として扱い、例外の語を取り除いた後に直後の 3 バイトで長音符を見分ける)
LC_ALL=C awk -v mode="$mode" -v words_file="$words_file" -v exceptions_file="$exceptions_file" '
BEGIN {
  choon = "ー"
  n_words = 0
  while ((r = (getline l < words_file)) > 0) {
    sub(/\r$/, "", l)
    if (l ~ /^[[:space:]]*(#|$)/) continue
    t = index(l, "\t")
    if (t == 0) continue
    n_words++
    bad_word[n_words] = substr(l, 1, t - 1)
    good_word[n_words] = substr(l, t + 1)
  }
  if (r < 0) exit 2
  close(words_file)
  if (n_words == 0) exit 2

  n_exc = 0
  while ((r = (getline l < exceptions_file)) > 0) {
    sub(/\r$/, "", l)
    if (l ~ /^[[:space:]]*(#|$)/) continue
    n_exc++
    exc[n_exc] = l
  }
  if (r < 0) exit 2
  close(exceptions_file)
  in_hunk = 0
}

function check_line(file_idx, line_no, text,    work, i, p, bad, good, blen, rest, after) {
  sub(/\r$/, "", text)
  if (index(text, "katakana: ignore") > 0) {
    return
  }
  work = text
  for (i = 1; i <= n_exc; i++) {
    while ((p = index(work, exc[i])) > 0) {
      work = substr(work, 1, p - 1) " " substr(work, p + length(exc[i]))
    }
  }
  for (i = 1; i <= n_words; i++) {
    bad = bad_word[i]
    good = good_word[i]
    blen = length(bad)
    rest = work
    while ((p = index(rest, bad)) > 0) {
      after = substr(rest, p + blen, 3)
      if (after != choon) {
        printf "%s\t%s\t%s\t%s\n", file_idx, line_no, bad, good
        rest = substr(rest, p + blen)
      } else {
        rest = substr(rest, p + blen + 3)
      }
    }
  }
}

mode == "all" && /^F/ {
  t = index($0, "\t")
  cur_idx = substr($0, 2, t - 2)
  cur_file = substr($0, t + 1)
  line_no = 0
  while ((r = (getline l < cur_file)) > 0) {
    line_no++
    check_line(cur_idx, line_no, l)
  }
  if (r < 0) exit 2
  close(cur_file)
  next
}

mode == "diff" {
  if (substr($0, 1, 1) == "F") {
    cur_idx = substr($0, 2)
    in_hunk = 0
  } else if (substr($0, 1, 3) == "@@ ") {
    p = index($0, " +")
    if (p > 0) {
      s = substr($0, p + 2)
      sub(/[^0-9].*$/, "", s)
      line_no = s + 0
      in_hunk = 1
    }
  } else if (in_hunk && substr($0, 1, 1) == "+") {
    check_line(cur_idx, line_no, substr($0, 2))
    line_no++
  }
}
' "$tmp/input" > "$tmp/findings" || die "検査に失敗した"

while IFS=$'\t' read -r idx line bad good; do
  report "${files[$idx]}" "$line" "$bad" "$good"
done < "$tmp/findings"

[ "$findings" = 0 ] || exit 1
exit 0
