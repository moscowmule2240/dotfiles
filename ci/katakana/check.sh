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

# git の blob が検査の対象か。通常ファイル以外 (symlink・submodule)・表そのもの・空ファイル・バイナリは外す。
# 対象なら中身を $tmp/blob に書き出したまま 0 を返す
prepare_target_blob() {
  case "$1" in 100*) ;; *) return 1 ;; esac
  case "$3" in
    ci/katakana/words.tsv | ci/katakana/exceptions.txt) return 1 ;;
  esac
  git cat-file blob "$2" > "$tmp/blob" || die "git cat-file が失敗した ($3)"
  [ -s "$tmp/blob" ] || return 1
  LC_ALL=C grep -Iq . < "$tmp/blob"
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
mkdir -p "$tmp/blobs" || die "作業ディレクトリーを作れない"
: > "$tmp/input"
files=()
tab=$'\t'
if [ "$mode" = all ]; then
  if git rev-parse --verify -q HEAD >/dev/null; then
    git ls-tree -r -z HEAD > "$tmp/list" || die "git ls-tree が失敗した"
    while IFS= read -r -d '' entry; do
      meta=${entry%%"$tab"*}
      f=${entry#*"$tab"}
      mode_bits=''
      obj_type=''
      sha=''
      IFS=' ' read -r mode_bits obj_type sha <<EOF
$meta
EOF
      [ "$obj_type" = blob ] || continue
      prepare_target_blob "$mode_bits" "$sha" "$f" || continue
      idx=${#files[@]}
      files+=("$f")
      mv "$tmp/blob" "$tmp/blobs/$idx" || die "一時ファイルを移せない"
      printf '=W\t%s\t%s\n' "$idx" "$tmp/blobs/$idx" >> "$tmp/input"
    done < "$tmp/list"
  fi
else
  git diff -z --raw --no-abbrev --no-ext-diff --diff-filter=ACMRT -M "$merge_base" "$head" > "$tmp/status" || die "git diff が失敗した"
  while IFS= read -r -d '' meta; do
    IFS= read -r -d '' old || break
    new=$old
    old_mode=''
    new_mode=''
    old_sha=''
    new_sha=''
    st=''
    IFS=' ' read -r old_mode new_mode old_sha new_sha st <<EOF
$meta
EOF
    case "$st" in R* | C*) IFS= read -r -d '' new || break ;; esac
    old_mode=${old_mode#:}
    case "$old_mode" in
      100*) [ "$old_sha" = "$new_sha" ] && continue ;;
    esac
    prepare_target_blob "$new_mode" "$new_sha" "$new" || continue
    idx=${#files[@]}
    files+=("$new")
    case "$old_mode" in
      100*)
        printf '=D\t%s\n' "$idx" >> "$tmp/input"
        git diff -U0 -a --no-textconv --no-color --no-ext-diff "$old_sha" "$new_sha" >> "$tmp/input" ||
          die "git diff が失敗した"
        ;;
      *)
        mv "$tmp/blob" "$tmp/blobs/$idx" || die "一時ファイルを移せない"
        printf '=W\t%s\t%s\n' "$idx" "$tmp/blobs/$idx" >> "$tmp/input"
        ;;
    esac
  done < "$tmp/status"
fi

if [ ! -s "$tmp/input" ]; then
  exit 0
fi

# ---- 出現ごとの照合 (LC_ALL=C でバイト列として扱い、例外の語を取り除いた後に直後の 3 バイトで長音符を見分ける)
LC_ALL=C awk -v words_file="$words_file" -v exceptions_file="$exceptions_file" '
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

{
  if (substr($0, 1, 3) == "=W\t") {
    in_hunk = 0
    rest_line = substr($0, 4)
    t = index(rest_line, "\t")
    cur_idx = substr(rest_line, 1, t - 1)
    blob_path = substr(rest_line, t + 1)
    line_no = 0
    while ((r = (getline l < blob_path)) > 0) {
      line_no++
      check_line(cur_idx, line_no, l)
    }
    if (r < 0) exit 2
    close(blob_path)
  } else if (substr($0, 1, 3) == "=D\t") {
    cur_idx = substr($0, 4)
    in_hunk = 0
  } else if (substr($0, 1, 11) == "diff --git ") {
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
