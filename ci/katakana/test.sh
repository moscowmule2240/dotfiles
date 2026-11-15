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
# 利用者の git 設定 (diff.interHunkContext や core.autocrlf 等) の影響を切る
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

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
  out=$(unset GITHUB_ACTIONS && cd "$dir" && "$BASH" "$check" "$@" 2>&1)
  rc=$?
  out_shown=false
}

run_check_gha() {
  dir=$1
  shift
  out=$(cd "$dir" && GITHUB_ACTIONS=true "$BASH" "$check" "$@" 2>&1)
  rc=$?
  out_shown=false
}

# 1 つのテストの中の失敗を数え、終わりに合否を記録する
begin() { name=$1; problems=""; out=""; rc=""; out_shown=false; }
record_out() {
  if ! $out_shown; then
    out_shown=true
    if [ -n "$out" ]; then
      while IFS= read -r line; do
        problems="$problems
    | $line"
      done <<EOF
$out
EOF
    else
      problems="$problems
    | (出力なし)"
    fi
  fi
}
fail_because() {
  problems="$problems
  - $1"
  record_out
}
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
  fi
}

# 足した行 (バイナリからテキストへの書き換えを含む) の省略形を指摘して exit 1 にし、正しい表記の行は指摘しない
test_added_line_detected() {
  begin test_added_line_detected
  new_repo
  printf '最初の行\n' > "$r/doc.md"
  printf 'bin\000\n' > "$r/from-bin.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '最初の行\nサーバを立てる\nコンテナを動かす\nブラウザーで開く\nエミュレータを使う\n' > "$r/doc.md" # katakana: ignore
  printf 'サーバに変わる\n' > "$r/from-bin.md" # katakana: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 1
  expect_out 'doc.md:2: サーバ -> サーバー' # katakana: ignore
  expect_out 'doc.md:3: コンテナ -> コンテナー' # katakana: ignore
  expect_out 'doc.md:5: エミュレータ -> エミュレーター' # katakana: ignore
  expect_out 'from-bin.md:1: サーバ -> サーバー' # katakana: ignore
  expect_no_out 'doc.md:1:'
  expect_no_out 'doc.md:4:'
  end
}

# 変更の無い既存の行や、base 側だけで直したファイルは指摘しない (--all では既存の行も拾う)
test_unchanged_and_three_dot_diff() {
  begin test_unchanged_and_three_dot_diff
  new_repo
  printf '既存のサーバの記述\n' > "$r/edit.md" # katakana: ignore
  printf '既存のポインタ\n' > "$r/main-only.md" # katakana: ignore
  commit "$r" init
  git -C "$r" switch -q -c pr
  printf '既存のサーバの記述\n新しく足したサーバーの記述\n' > "$r/edit.md" # katakana: ignore
  commit "$r" pr
  pr=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q main
  printf '既存のポインター\n' > "$r/main-only.md"
  commit "$r" main-only
  main=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q pr
  run_check "$r" "$main" "$pr"
  expect_rc 0
  run_check "$r" --all
  expect_rc 1
  expect_out 'edit.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'main-only.md:1: ポインタ -> ポインター' # katakana: ignore
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
  printf 'アカウンタビリティとアダプタビリティとアダプタブルとエディタブルとサーバントとバッファローとユーザビリティとモニタリングとフィルタリングとマスタリングとバッファリング\n' > "$r/a.md" # katakana: ignore
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
  run_check_gha "$r" --all
  expect_rc 1
  expect_out '::error file=a%2Cb%3Ac.md,line=2::ポインタ -> ポインター' # katakana: ignore
  end
}

# 削除したファイル・バイナリのファイル・改名しただけの既存の行で落ちず、不正な引数では exit 2 にする
test_deleted_binary_rename_and_errors() {
  begin test_deleted_binary_rename_and_errors
  new_repo
  printf '消すサーバの行\n' > "$r/gone.md" # katakana: ignore
  printf '1 行目の説明文\n2 行目の説明文\nもとからあるブラウザの行\n4 行目の説明文\n' > "$r/keep.md" # katakana: ignore
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" rm -q gone.md
  git -C "$r" mv keep.md moved.md
  printf '新しく足したブラウザーの行\n' >> "$r/moved.md"
  printf 'サーバ\n\000\n' > "$r/bin.dat" # katakana: ignore
  ln -s サーバ.md "$r/link.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 0
  run_check "$r" --all
  expect_rc 1
  expect_out 'moved.md:3: ブラウザ -> ブラウザー' # katakana: ignore
  expect_no_out 'bin.dat'
  expect_no_out 'link.md'
  run_check "$r" "$base" 1234567890abcdef1234567890abcdef12345678
  expect_rc 2
  expect_out 'head (1234567890abcdef1234567890abcdef12345678) が commit ではない'
  run_check "$r" 0000000000000000000000000000000000000000 1234567890abcdef1234567890abcdef12345678
  expect_rc 2
  expect_out 'head (1234567890abcdef1234567890abcdef12345678) が commit ではない'
  run_check "$r" '' "$head"
  expect_rc 2
  expect_out 'base () が commit ではない'
  run_check "$r" not-a-ref "$head"
  expect_rc 2
  expect_out 'base (not-a-ref) が commit ではない'
  run_check "$r" 1234567 "$head"
  expect_rc 2
  expect_out 'base (1234567) が commit ではない'
  tree=$(git -C "$r" rev-parse "$head^{tree}")
  run_check "$r" "$tree" "$head"
  expect_rc 2
  expect_out "base ($tree) が commit ではない"
  printf 'あとから足したサーバ\n' > "$r/later.md" # katakana: ignore
  commit "$r" later
  later=$(git -C "$r" rev-parse HEAD)
  printf '問題の無い行\n' > "$r/ok.md"
  commit "$r" latest
  run_check "$r" "$base" "$head"
  expect_rc 0
  expect_no_out 'later.md'
  run_check "$r" "$head" "$later"
  expect_rc 1
  expect_out 'later.md:1: サーバ -> サーバー' # katakana: ignore
  expect_no_out 'ok.md'
  end
}

# 直下に「-」というファイルがあっても標準入力として読まれず、後ろのファイルも検査される
test_dash_filename_and_following_files() {
  begin test_dash_filename_and_following_files
  new_repo
  printf '最初のファイル\n' > "$r/a.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf 'サーバ\n' > "$r/-" # katakana: ignore
  printf 'コンテナ\n' > "$r/z.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_out '-:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'z.md:1: コンテナ -> コンテナー' # katakana: ignore
  run_check "$r" --all
  expect_rc 1
  expect_out '-:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'z.md:1: コンテナ -> コンテナー' # katakana: ignore
  end
}

# working-tree-encoding で作業ツリーがバイナリに見えるファイルも git の blob から検査する
test_working_tree_encoding_utf16le() {
  begin test_working_tree_encoding_utf16le
  new_repo
  printf 'utf16.md working-tree-encoding=UTF-16LE\n' > "$r/.gitattributes"
  printf '最初の行\n' | iconv -f UTF-8 -t UTF-16LE > "$r/utf16.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '最初の行\nサーバを足す\n' | iconv -f UTF-8 -t UTF-16LE > "$r/utf16.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_out 'utf16.md:2: サーバ -> サーバー' # katakana: ignore
  run_check "$r" --all
  expect_rc 1
  expect_out 'utf16.md:2: サーバ -> サーバー' # katakana: ignore
  end
}

# symlink からファイルへの typechange で見出しを 0 行目として誤照合せず、ファイルから symlink への typechange は外す
test_typechange_symlink_and_file() {
  begin test_typechange_symlink_and_file
  new_repo
  printf '通常の内容\n' > "$r/target.md"
  ln -s target.md "$r/サーバ.md" # katakana: ignore
  printf '消える前にあった行\n' > "$r/to-link.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  rm "$r/サーバ.md" # katakana: ignore
  printf '1 行目は正しいサーバー\n2 行目はサーバ\n' > "$r/サーバ.md" # katakana: ignore
  rm "$r/to-link.md"
  ln -s サーバ.md "$r/to-link.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_no_out 'サーバ.md:0:' # katakana: ignore
  expect_no_out 'サーバ.md:1:' # katakana: ignore
  expect_out 'サーバ.md:2: サーバ -> サーバー' # katakana: ignore
  expect_no_out 'to-link.md'
  end
}

# diff.interHunkContext と diff.suppressBlankEmpty=true で空の文脈行を含む hunk がまとまっても、文脈行の分だけ行番号を進められる
test_interhunk_context_line_numbers() {
  begin test_interhunk_context_line_numbers
  new_repo
  printf '1 行目\n2 行目\n\n4 行目\n5 行目\n6 行目\n' > "$r/doc.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '1 行目\nサーバの行\n\n4 行目\n5 行目\nコンテナの行\n' > "$r/doc.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  git -C "$r" config diff.interHunkContext 5
  git -C "$r" config diff.suppressBlankEmpty true
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_out 'doc.md:2: サーバ -> サーバー' # katakana: ignore
  expect_out 'doc.md:6: コンテナ -> コンテナー' # katakana: ignore
  end
}

# 50 バイト行を $1 行と末尾の 'a' を $2 文字出力し、NUL のオフセットを厳密に揃える
repeat_a() {
  awk -v lines="$1" -v tail="$2" 'BEGIN {
    l = ""
    for (i = 0; i < 49; i++) l = l "a"
    for (i = 0; i < lines; i++) print l
    for (i = 0; i < tail; i++) printf "a"
  }'
}

# 8000 バイト境界 (オフセット 7999 はバイナリ、8000 はテキスト) と、行途中の NUL の後ろを =W・=D・--all で検査できること
test_late_nul_detected_beyond_8000_bytes() {
  begin test_late_nul_detected_beyond_8000_bytes
  new_repo
  {
    printf 'ok\n'
    repeat_a 159 46
    printf '\n'
  } > "$r/mod-nul.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  {
    printf 'サーバ\n' # katakana: ignore
    repeat_a 159 39
    printf '\000\n'
  } > "$r/bin-at-7999.dat"
  {
    printf 'サーバ\n' # katakana: ignore
    repeat_a 159 38
    printf '\nx\000サーバ tail\n' # katakana: ignore
  } > "$r/nul-at-8000.md"
  printf 'x\000サーバ tail\n' >> "$r/mod-nul.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_no_out 'bin-at-7999.dat'
  expect_out 'nul-at-8000.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'nul-at-8000.md:162: サーバ -> サーバー' # katakana: ignore
  expect_out 'mod-nul.md:162: サーバ -> サーバー' # katakana: ignore
  run_check "$r" --all
  expect_rc 1
  expect_no_out 'bin-at-7999.dat'
  expect_out 'nul-at-8000.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'nul-at-8000.md:162: サーバ -> サーバー' # katakana: ignore
  expect_out 'mod-nul.md:162: サーバ -> サーバー' # katakana: ignore
  end
}

# パイプのバッファーを超える大きさ (約 200 KB) の blob で、SIGPIPE を失敗と誤認せず末尾近くまで =W・=D・--all で検査できること
test_large_blob_beyond_pipe_buffer() {
  begin test_large_blob_beyond_pipe_buffer
  new_repo
  {
    printf '先頭はOK\n'
    repeat_a 4000 0
  } > "$r/large-mod.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  {
    printf '1 行目のポインタ\n' # katakana: ignore
    repeat_a 4000 0
    printf '末尾のブラウザ\n' # katakana: ignore
  } > "$r/large-add.md"
  {
    printf '1 行目のサーバ\n' # katakana: ignore
    repeat_a 4000 0
    printf '末尾のコンテナ\n' # katakana: ignore
  } > "$r/large-mod.md"
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" "$base" "$head"
  expect_rc 1
  expect_out 'large-add.md:1: ポインタ -> ポインター' # katakana: ignore
  expect_out 'large-add.md:4002: ブラウザ -> ブラウザー' # katakana: ignore
  expect_out 'large-mod.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'large-mod.md:4002: コンテナ -> コンテナー' # katakana: ignore
  run_check "$r" --all
  expect_rc 1
  expect_out 'large-add.md:1: ポインタ -> ポインター' # katakana: ignore
  expect_out 'large-add.md:4002: ブラウザ -> ブラウザー' # katakana: ignore
  expect_out 'large-mod.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'large-mod.md:4002: コンテナ -> コンテナー' # katakana: ignore
  end
}

# base がすべて 0 または存在しない 40/64 桁の SHA のときは、省略形があっても検査せず notice で exit 0 にする
test_missing_base_skips() {
  begin test_missing_base_skips
  new_repo
  printf 'サーバの記述\n' > "$r/doc.md" # katakana: ignore
  commit "$r" base
  printf 'コンテナの記述\n' > "$r/added.md" # katakana: ignore
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" --all
  expect_rc 1
  expect_out 'doc.md:1: サーバ -> サーバー' # katakana: ignore
  expect_out 'added.md:1: コンテナ -> コンテナー' # katakana: ignore
  zero40='0000000000000000000000000000000000000000'
  zero64='0000000000000000000000000000000000000000000000000000000000000000'
  missing40='1234567890abcdef1234567890abcdef12345678'
  missing64='1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
  for b in "$zero40" "$zero64" "$missing40" "$missing64"; do
    run_check "$r" "$b" "$head"
    expect_rc 0
    expect_out "比べる元が無いので検査しない (base: $b)"
    expect_no_out '::notice::'
    expect_no_out 'doc.md'
    expect_no_out 'added.md'
    run_check_gha "$r" "$b" "$head"
    expect_rc 0
    expect_out "::notice::比べる元が無いので検査しない (base: $b)"
    expect_no_out 'doc.md'
    expect_no_out 'added.md'
  done
  end
}

# shallow clone で境界の外にある commit を base に渡したときは、skip せず exit 2 にする
test_shallow_clone_missing_base_fails() {
  begin test_shallow_clone_missing_base_fails
  new_repo
  printf '1 つ目の行\n' > "$r/a.md"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '2 つ目の行\n' >> "$r/a.md"
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  shallow_parent=$(mktemp -d "$work/shallow.XXXXXX") || exit 1
  shallow="$shallow_parent/repo"
  git clone -q --depth 1 "file://$r" "$shallow" || exit 1
  run_check "$shallow" "$base" "$head"
  expect_rc 2
  expect_out "base ($base) が commit ではない"
  expect_no_out '比べる元が無いので検査しない'
  end
}

test_added_line_detected
test_unchanged_and_three_dot_diff
test_same_line_occurrence_matching
test_exceptions_and_compounds
test_ignore_marker_and_y_words_and_tables
test_github_annotations
test_deleted_binary_rename_and_errors
test_missing_base_skips
test_shallow_clone_missing_base_fails
test_dash_filename_and_following_files
test_working_tree_encoding_utf16le
test_typechange_symlink_and_file
test_interhunk_context_line_numbers
test_late_nul_detected_beyond_8000_bytes
test_large_blob_beyond_pipe_buffer

echo "passed: $passed, failed: $failed"
[ "$failed" = 0 ] || { echo "failed:$failed_names"; exit 1; }
