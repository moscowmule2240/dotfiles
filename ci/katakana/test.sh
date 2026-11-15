#!/bin/bash
# check.sh の振る舞いを、使い捨ての git リポジトリで確かめる。
# 使い方: bash ci/katakana/test.sh
#   fixture に省略形を書く行には、このファイル自身が検査に当たらないよう行末に目印を付けている
#   (書き出すファイルには目印は入らない)。
set -u

here=$(cd "$(dirname "$0")" && pwd)
check="$here/check.sh"
repo_root=$(git -C "$here" rev-parse --show-toplevel) || exit 1

# CI の step には GITHUB_ACTIONS=true が入る。注釈の形を確かめるテストだけが明示して渡す
unset GITHUB_ACTIONS

mkdir -p "$repo_root/.temp/katakana-test" || exit 1
work=$(mktemp -d "$repo_root/.temp/katakana-test/run.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT

passed=0
failed=0
failed_names=""

# 使い捨てのリポジトリを作る。CI には git の identity が無く、手元は署名に agent が要るため、
# このリポジトリの local の config にだけ identity と署名なしを書く (本物のリポジトリには触らない)
new_repo() {
  r=$(mktemp -d "$work/repo.XXXXXX") || exit 1
  git -C "$r" init -q -b main
  git -C "$r" config user.name t
  git -C "$r" config user.email t@example.invalid
  git -C "$r" config commit.gpgsign false
}

commit() {
  git -C "$1" add -A && git -C "$1" commit -q --allow-empty -m "$2"
}

# check.sh を $1 のディレクトリーで流し、出力を $out、終了コードを $rc に入れる
run_check() {
  dir=$1
  shift
  out=$(cd "$dir" && bash "$check" "$@" 2>&1)
  rc=$?
}

# 1 つのテストの中の失敗を数え、終わりに合否を記録する
begin() { name=$1; problems=""; }
fail_because() { problems="$problems
  - $1"; }
expect_rc() { [ "$rc" = "$1" ] || fail_because "exit $rc (期待は $1)"; }
expect_out() { case "$out" in *"$1"*) ;; *) fail_because "出力に「$1」が無い" ;; esac; }
expect_no_out() { case "$out" in *"$1"*) fail_because "出力に「$1」がある" ;; esac; }
end() {
  if [ -z "$problems" ]; then
    passed=$((passed + 1))
    echo "PASS $name"
  else
    failed=$((failed + 1))
    failed_names="$failed_names $name"
    echo "FAIL $name$problems"
    printf '%s\n' "$out" | sed 's/^/    | /'
  fi
}

# 足した行の省略形を指摘して exit 1 にし、正しい表記の行は指摘しない
test_added_line_detected() {
  begin test_added_line_detected
  new_repo
  printf '最初の行\n' > "$r/doc.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '*.md -diff\n' > "$r/.gitattributes"
  printf '最初の行\nサーバを立てる\nコンテナを動かす\nブラウザーで開く\n' > "$r/doc.md" # katakana: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 1
  expect_out 'doc.md:2: サーバ -> サーバー' # katakana: ignore
  expect_out 'doc.md:3: コンテナ -> コンテナー' # katakana: ignore
  expect_no_out 'doc.md:1:'
  expect_no_out 'doc.md:4:'
  end
}

# 変更の無い既存の行や、merge-base から見て base 側だけで入った省略形は指摘しない (--all では既存の行も拾う)
test_unchanged_and_three_dot_diff() {
  begin test_unchanged_and_three_dot_diff
  new_repo
  printf '既存のサーバの記述\n' > "$r/edit.md" # katakana: ignore
  printf '共通の行\n' > "$r/main-only.md"
  commit "$r" init
  git -C "$r" switch -q -c pr
  printf '既存のサーバの記述\n新しく足したサーバーの記述\n' > "$r/edit.md" # katakana: ignore
  commit "$r" pr
  pr=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q main
  printf '共通の行\nポインタを足す\n' > "$r/main-only.md" # katakana: ignore
  commit "$r" main-only
  main=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q pr
  run_check "$r" "$main" "$pr"
  expect_rc 0
  run_check "$r" --all
  expect_rc 1
  expect_out 'edit.md:1: サーバ -> サーバー' # katakana: ignore
  end
}

# 出現ごとに照合し、「サーバー」は指摘せず、同じ行の「サーバー」と「サーバ」は後者だけを指摘する # katakana: ignore
test_same_line_occurrence_matching() {
  begin test_same_line_occurrence_matching
  new_repo
  printf 'サーバーだけを置く\nサーバーとサーバを同じ行に置く\n前のサーバーと後ろのサーバー\n' > "$r/a.md" # katakana: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_out 'a.md:2: サーバ -> サーバー' # katakana: ignore
  expect_no_out 'a.md:1:'
  expect_no_out 'a.md:3:'
  end
}

# 例外の表の語は指摘せず、同じ行の別の省略形や例外に無い複合語は指摘する
test_exceptions_and_compounds() {
  begin test_exceptions_and_compounds
  new_repo
  printf 'ユーザビリティとモニタリングとフィルタリングとマスタリングとバッファリング\n' > "$r/a.md" # katakana: ignore
  printf 'ユーザビリティの高いユーザ向け画面\n' >> "$r/a.md" # katakana: ignore
  printf 'サーバレスとコンテナイメージ\n' >> "$r/a.md" # katakana: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_no_out 'a.md:1:'
  expect_out 'a.md:2: ユーザ -> ユーザー' # katakana: ignore
  expect_out 'a.md:3: サーバ -> サーバー' # katakana: ignore
  expect_out 'a.md:3: コンテナ -> コンテナー' # katakana: ignore
  end
}

# katakana: ignore のある行、語末が -y の語、表そのもののファイルは指摘しない
test_ignore_marker_and_y_words_and_tables() {
  begin test_ignore_marker_and_y_words_and_tables
  new_repo
  mkdir -p "$r/ci/katakana"
  printf '外部のエラー文: サーバが見つかりません <!-- katakana: ignore -->\n' > "$r/a.md"
  printf 'msg="コンテナ停止" # katakana: ignore\n' > "$r/a.sh"
  printf 'ディレクトリとリポジトリとメモリとカテゴリとライブラリ\n' > "$r/y.md"
  printf 'サーバ\tサーバー\n' > "$r/ci/katakana/words.tsv" # katakana: ignore
  printf 'ユーザビリティ\n' > "$r/ci/katakana/exceptions.txt" # katakana: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  end
}

# GITHUB_ACTIONS=true のときは ::error file=...,line=...:: の注釈の形で出す
test_github_annotations() {
  begin test_github_annotations
  new_repo
  printf '1 行目\nポインタを渡す\n' > "$r/a,b:c.md" # katakana: ignore
  commit "$r" init
  out=$(cd "$r" && GITHUB_ACTIONS=true bash "$check" --all 2>&1)
  rc=$?
  expect_rc 1
  expect_out '::error file=a%2Cb%3Ac.md,line=2::ポインタ -> ポインター' # katakana: ignore
  end
}

# 削除したファイル・バイナリのファイル・改名しただけの既存の行で落ちず、不正な引数では exit 2 にする
test_deleted_binary_rename_and_errors() {
  begin test_deleted_binary_rename_and_errors
  new_repo
  printf '消すサーバの行\n' > "$r/gone.md" # katakana: ignore
  printf 'もとからあるブラウザの行\n' > "$r/keep.md" # katakana: ignore
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" rm -q gone.md
  git -C "$r" mv keep.md moved.md
  printf '新しく足したブラウザーの行\n' >> "$r/moved.md"
  printf '\000サーバ\n' > "$r/bin.dat" # katakana: ignore
  ln -s moved.md "$r/link.md"
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 0
  run_check "$r" --all
  expect_rc 1
  expect_out 'moved.md:1: ブラウザ -> ブラウザー' # katakana: ignore
  expect_no_out 'bin.dat'
  expect_no_out 'link.md'
  run_check "$r" "$base" 1234567890abcdef1234567890abcdef12345678
  expect_rc 2
  run_check "$r" "$base" "$base"
  expect_rc 2
  end
}

test_added_line_detected
test_unchanged_and_three_dot_diff
test_same_line_occurrence_matching
test_exceptions_and_compounds
test_ignore_marker_and_y_words_and_tables
test_github_annotations
test_deleted_binary_rename_and_errors

echo "passed: $passed, failed: $failed"
[ "$failed" = 0 ] || { echo "failed:$failed_names"; exit 1; }
