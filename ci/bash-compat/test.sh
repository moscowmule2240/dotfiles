#!/bin/bash
# check.sh の振る舞いを、使い捨ての git リポジトリで確かめる。
# 使い方: bash ci/bash-compat/test.sh
#   BASH32 が空なら、/bin/bash が 3.2 のときだけそれを使い、それ以外は Docker の経路で確かめる。
#   fixture の中の bash 4 の構文の行には、このファイル自身が検査に当たらないよう行末に目印を付けている
#   (書き出すファイルには目印は入らない)。
set -u

here=$(cd "$(dirname "$0")" && pwd)
check="$here/check.sh"
repo_root=$(git -C "$here" rev-parse --show-toplevel) || exit 1

# BASH32 が未設定のときだけ、/bin/bash が 3.2 ならそれを使う。空を渡すと Docker の経路を通る (Mac でも確かめられる)
if [ -z "${BASH32+set}" ] && /bin/bash -c '[ "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}" = 3.2 ]' 2>/dev/null; then
  BASH32=/bin/bash
fi
export BASH32="${BASH32:-}"
# CI の step には GITHUB_ACTIONS=true が入る。注釈の形を確かめるテストだけが明示して渡す
unset GITHUB_ACTIONS

mkdir -p "$repo_root/.temp/bash-compat-test" || exit 1
work=$(mktemp -d "$repo_root/.temp/bash-compat-test/run.XXXXXX") || exit 1
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

test_bash4_syntax_table() {
  pats=()
  pats+=('declare -A m') # bash-compat: ignore
  pats+=('declare -gA m') # bash-compat: ignore
  pats+=('  local -n r=x') # bash-compat: ignore
  pats+=('typeset -u up') # bash-compat: ignore
  pats+=('declare -l low') # bash-compat: ignore
  pats+=('local -') # bash-compat: ignore
  pats+=('echo "${x,,}"') # bash-compat: ignore
  pats+=('echo "${x^^}"') # bash-compat: ignore
  pats+=('echo "${x,}"') # bash-compat: ignore
  pats+=('echo "${x^}"') # bash-compat: ignore
  pats+=('echo "${x@Q}"') # bash-compat: ignore
  pats+=('echo "${x:0:-1}"') # bash-compat: ignore
  pats+=('echo "${a[-1]}"') # bash-compat: ignore
  pats+=('mapfile -t a < f') # bash-compat: ignore
  pats+=('readarray -t a < f') # bash-compat: ignore
  pats+=('read -rN 3 v') # bash-compat: ignore
  pats+=('exec {fd}>f') # bash-compat: ignore
  pats+=("printf '%(%F)T\\n' -1") # bash-compat: ignore
  pats+=('shopt -s globstar') # bash-compat: ignore
  pats+=('shopt -s lastpipe') # bash-compat: ignore
  pats+=('wait -n') # bash-compat: ignore
  pats+=('[[ -v x ]] && echo y') # bash-compat: ignore
  pats+=('[ -v x ] && echo y') # bash-compat: ignore
  pats+=('test -v x && echo y') # bash-compat: ignore
  pats+=('echo "$EPOCHSECONDS"') # bash-compat: ignore
  pats+=('echo "$EPOCHREALTIME"') # bash-compat: ignore
  pats+=('echo "$BASH_ARGV0"') # bash-compat: ignore
  pats+=('coproc cat') # bash-compat: ignore
  pats+=('echo {1..10..2}') # bash-compat: ignore
  pats+=('echo {01..03}') # bash-compat: ignore
  pats+=('echo "$BASHPID"') # bash-compat: ignore
  pats+=('echo "${1,,}"') # bash-compat: ignore
  pats+=('echo "${@^^}"') # bash-compat: ignore
  pats+=('echo "${1@Q}"') # bash-compat: ignore
  pats+=('echo "${1:0:-1}"') # bash-compat: ignore
  pats+=('echo "${x::-1}"') # bash-compat: ignore
  pats+=('echo "${!ref,,}"') # bash-compat: ignore
  pats+=('echo "${!ref@Q}"') # bash-compat: ignore
  pats+=('echo "${a[0]:0:-1}"') # bash-compat: ignore
  pats+=('echo "${x:0:-n}"') # bash-compat: ignore
  pats+=('echo "${x:0:-$n}"') # bash-compat: ignore
  pats+=('echo "$SRANDOM"') # bash-compat: ignore
  pats+=('read -e -i def v') # bash-compat: ignore
  pats+=('wait -p id') # bash-compat: ignore
  pats+=('wait -f') # bash-compat: ignore
  pats+=('[ ! -v x ] && echo y') # bash-compat: ignore
  i=0
  while [ "$i" -lt "${#pats[@]}" ]; do
    begin "test_bash4_syntax_table[${pats[$i]}]"
    new_repo
    printf '#!/bin/bash\necho x\n%s\n' "${pats[$i]}" > "$r/a.sh"
    commit "$r" init
    run_check "$r" --all
    expect_rc 1
    expect_out 'a.sh:3: bash4-syntax'
    end
    i=$((i + 1))
  done
}

test_bash32_parse_fails() {
  begin test_bash32_parse_fails
  new_repo
  printf '#!/bin/bash\ncase x in\n  x) echo a ;&\n  y) echo b ;;\nesac\n' > "$r/b.sh"
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_out 'b.sh:'
  expect_out 'bash32'
  end
}

test_extensionless_shebang() {
  begin test_extensionless_shebang
  new_repo
  printf '#!/usr/bin/env bash\necho "${x,,}"\n' > "$r/tool" # bash-compat: ignore
  printf '#!/usr/bin/env -S bash -e\necho "${x,,}"\n' > "$r/tool2" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_out 'tool:'
  expect_out 'tool2:'
  end
}

# sh で起動して python へ渡す polyglot など、ほかの言語の拡張子のファイルは shebang が sh でも対象にしない
test_other_extension_skipped() {
  begin test_other_extension_skipped
  new_repo
  printf '#!/bin/sh\n""":" ; exec python3 "$0" "$@"\nprint("hi")\n"""\n' > "$r/tool.py"
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  expect_out '対象なし'
  end
}

test_zsh_skipped() {
  begin test_zsh_skipped
  new_repo
  printf 'typeset -A m\n' > "$r/z.zsh" # bash-compat: ignore
  printf '#!/usr/bin/env zsh\ntypeset -A m\n' > "$r/z.sh" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  expect_out '対象なし'
  end
}

test_comments_and_ignore() {
  begin test_comments_and_ignore
  new_repo
  printf '#!/bin/bash\n  # declare -A は使わない\necho "${EPOCHSECONDS:-0}" # bash-compat: ignore\n' > "$r/c.sh" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  end
}

test_linux_only_marker() {
  begin test_linux_only_marker
  new_repo
  printf '#!/bin/bash\n# bash-compat: linux-only\nmapfile -t a < /dev/null\necho "${a[@]}"\n' > "$r/l.sh" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  printf 'd=/tmp\ncd $d\n' >> "$r/l.sh"
  commit "$r" second
  run_check "$r" --all
  expect_rc 1
  expect_out 'SC2164'
  expect_no_out 'bash4-syntax'
  end
}

test_diff_checks_only_changed() {
  begin test_diff_checks_only_changed
  new_repo
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/old.sh" # bash-compat: ignore
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\necho ok\n' > "$r/new.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  end
}

test_three_dot_excludes_base_side() {
  begin test_three_dot_excludes_base_side
  # 分かれる前から指摘のある shared.sh を、main 側だけが変える。2 点の差分だと shared.sh が一覧に入り、
  # PR 側の (指摘のある) 中身を読んでしまう
  new_repo
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/shared.sh" # bash-compat: ignore
  commit "$r" init
  git -C "$r" switch -q -c pr
  printf '#!/bin/bash\necho ok\n' > "$r/pr.sh"
  commit "$r" pr
  pr=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q main
  printf '#!/bin/bash\necho fixed\n' > "$r/shared.sh"
  commit "$r" main-only
  main=$(git -C "$r" rev-parse HEAD)
  git -C "$r" switch -q pr
  run_check "$r" "$main" "$pr"
  expect_rc 0
  end
}

test_odd_names() {
  begin test_odd_names
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/gone.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" rm -q gone.sh
  for n in 'my script.sh' 'a,b.sh' $'nl\nname.sh'; do
    printf '#!/bin/bash\necho x\ndeclare -A m\n' > "$r/$n" # bash-compat: ignore
  done
  ln -s 'my script.sh' "$r/link.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 1
  expect_out 'my script.sh:'
  expect_out 'a,b.sh:'
  expect_out 'name.sh:'
  # 消したファイルは検査しない (消したことの警告だけが出る)
  printf '%s\n' "$out" | grep -q '^gone.sh:[0-9]' && fail_because "消した gone.sh を検査した"
  expect_no_out 'link.sh'
  end
}

test_missing_base_checks_all() {
  begin test_missing_base_checks_all
  new_repo
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/old.sh" # bash-compat: ignore
  commit "$r" base
  printf '#!/bin/bash\necho ok\n' > "$r/new.sh"
  commit "$r" head
  head=$(git -C "$r" rev-parse HEAD)
  run_check "$r" 0000000000000000000000000000000000000000 "$head"
  expect_rc 1
  expect_out 'old.sh'
  expect_out '比べる元が無い'
  run_check "$r" 1234567890abcdef1234567890abcdef12345678 "$head"
  expect_rc 1
  expect_out 'old.sh'
  expect_out '比べる元が無い'
  end
}

test_head_missing_fails() {
  begin test_head_missing_fails
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/ok.sh"
  commit "$r" base
  run_check "$r" "$(git -C "$r" rev-parse HEAD)" 1234567890abcdef1234567890abcdef12345678
  expect_rc 2
  expect_out 'が commit ではない'
  end
}

test_head_not_checked_out_fails() {
  begin test_head_not_checked_out_fails
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/ok.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  commit "$r" head
  run_check "$r" "$base" "$base"
  expect_rc 2
  expect_out '作業ツリーの HEAD が'
  end
}

test_weakening_changes_warn() {
  begin test_weakening_changes_warn
  new_repo
  mkdir -p "$r/.github/workflows" "$r/sub" "$r/ci/bash-compat"
  printf 'on: push\n' > "$r/.github/workflows/x.yml"
  printf 'disable=SC1091\n' > "$r/sub/.shellcheckrc"
  printf '#!/bin/bash\necho a\n' > "$r/ci/bash-compat/check.sh"
  printf '#!/bin/bash\necho k\n' > "$r/k.sh"
  # shebang が無く、拡張子だけで対象になっているファイル。.zsh に変えると対象から外れる
  printf 'echo m\n' > "$r/m.sh"
  printf '#!/bin/bash\necho t\n' > "$r/t"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf 'on: pull_request\n' > "$r/.github/workflows/x.yml"
  printf 'disable=SC2086\n' > "$r/sub/.shellcheckrc"
  printf '#!/bin/bash\necho b\n' > "$r/ci/bash-compat/check.sh"
  printf '#!/bin/bash\n# bash-compat: linux-only\n# shellcheck disable=SC2086\necho k\n' > "$r/k.sh"
  git -C "$r" mv m.sh m.zsh
  printf '#!/usr/bin/env zsh\necho t\n' > "$r/t"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  n=$(printf '%s\n' "$out" | grep -c ': warning: ')
  [ "$n" = 7 ] || fail_because "警告の行が $n (期待は 7)"
  for w in .github/workflows/x.yml sub/.shellcheckrc ci/bash-compat/check.sh k.sh m.sh t; do
    printf '%s\n' "$out" | grep -q "^${w}[:]" || fail_because "$w の警告が無い"
  done
  end
}

test_github_annotations() {
  begin test_github_annotations
  new_repo
  printf '#!/bin/bash\necho x\ndeclare -A m\n' > "$r/a,b.sh" # bash-compat: ignore
  commit "$r" init
  out=$(cd "$r" && GITHUB_ACTIONS=true bash "$check" --all 2>&1)
  rc=$?
  expect_rc 1
  expect_out '::error file=a%2Cb.sh,line=3::'
  end
}

test_bash32_unavailable_fails() {
  begin test_bash32_unavailable_fails
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/ok.sh"
  commit "$r" init
  out=$(cd "$r" && BASH32=/nonexistent/bash bash "$check" --all 2>&1)
  rc=$?
  expect_rc 2
  expect_out 'bash 3.2 を起動できない'
  end
}

test_bash32_not_32_fails() {
  begin test_bash32_not_32_fails
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/ok.sh"
  commit "$r" init
  printf '#!/bin/sh\necho 5.2.37\n' > "$work/fake-bash"
  chmod +x "$work/fake-bash"
  out=$(cd "$r" && BASH32="$work/fake-bash" bash "$check" --all 2>&1)
  rc=$?
  expect_rc 2
  expect_out 'bash 3.2 ではない'
  end
}

# .gitattributes の -diff で差分を binary にしても、足した目印と ignore を警告する
test_gitattributes_cannot_hide_markers() {
  begin test_gitattributes_cannot_hide_markers
  new_repo
  printf '#!/bin/bash\necho k\n' > "$r/k.sh"
  printf '#!/bin/bash\necho j\n' > "$r/j.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '*.sh -diff\n' > "$r/.gitattributes"
  printf '#!/bin/bash\n# bash-compat: linux-only\nmapfile -t a < /dev/null\necho "${a[@]}"\n' > "$r/k.sh" # bash-compat: ignore
  printf '#!/bin/bash\nx=1 # bash-compat: ignore\necho "$x"\n' > "$r/j.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  expect_out '.gitattributes: warning'
  expect_out 'k.sh: warning'
  expect_out 'j.sh:2: warning'
  end
}

# ShellCheck の指示は書き方 (空白の数・ほかのキーとの組み合わせ・shell=) によらず警告する
test_shellcheck_directive_variants_warn() {
  begin test_shellcheck_directive_variants_warn
  new_repo
  printf '#!/bin/bash\necho s\n' > "$r/s.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\n#  shellcheck  disable=SC2164\n# shellcheck source=/dev/null disable=SC2164\n# shellcheck shell=sh\necho s\n' > "$r/s.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  n=$(printf '%s\n' "$out" | grep -c '^s.sh:[0-9]*: warning')
  [ "$n" = 3 ] || fail_because "s.sh の警告が $n (期待は 3)"
  end
}

# bash の shebang があるのに拡張子で対象の外になるファイルを足したら警告する (.command への改名・書き換えも同じ)
test_other_extension_shebang_added_warns() {
  begin test_other_extension_shebang_added_warns
  new_repo
  printf 'x\n' > "$r/README"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/run.command" # bash-compat: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  expect_out 'run.command: warning'
  end
}

# 足した行を使わず、上の行を消して目印を先頭 10 行に入れたときも警告する
test_marker_moved_into_head_warns() {
  begin test_marker_moved_into_head_warns
  new_repo
  printf '#!/bin/bash\n:\n:\n:\n:\n:\n:\n:\n:\n:\n:\n# bash-compat: linux-only\necho m\n' > "$r/m.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\n:\n:\n:\n:\n:\n:\n:\n:\n# bash-compat: linux-only\nmapfile -t a < /dev/null\necho "${a[@]}"\n' > "$r/m.sh" # bash-compat: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  expect_out 'm.sh: warning'
  end
}

# 差分のパスは glob として読まない (a*.sh の差分に ab.sh の行を混ぜない)
test_literal_pathspec() {
  begin test_literal_pathspec
  new_repo
  printf '#!/bin/bash\necho a\n' > "$r/a*.sh"
  printf '#!/bin/bash\necho b\n' > "$r/ab.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\nx=1 # bash-compat: ignore\necho "$x"\n' > "$r/ab.sh"
  printf '#!/bin/bash\necho a2\n' > "$r/a*.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_out 'ab.sh:2: warning'
  expect_no_out 'a*.sh:'
  end
}

# 検査の対象のファイルを消したら警告する (書き換えて拡張子も shebang も無い名前へ移すと、改名として拾えない)
test_deleted_target_warns() {
  begin test_deleted_target_warns
  new_repo
  printf '#!/bin/bash\necho one\necho two\necho three\n' > "$r/lib.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" rm -q lib.sh
  printf 'x=1\ny=2\nz=3\nw=4\n' > "$r/lib"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  expect_out 'lib.sh: warning'
  end
}

# 改名しただけのファイルでは、もとからある目印・ignore・ShellCheck の指示を「足した」と言わない
test_rename_keeps_markers_quiet() {
  begin test_rename_keeps_markers_quiet
  new_repo
  printf '#!/bin/bash\n# bash-compat: linux-only\n# shellcheck disable=SC2086\nx=1 # bash-compat: ignore\necho $x\n' > "$r/p.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" mv p.sh q.sh
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 0
  expect_no_out 'warning'
  end
}

# 既定値・代入・代替・エラーの中の入れ子 (${2:-${PORT:-22}}・${T:=${D:-30}}・${p:+${T:-1}}・${p:?${T:-1}}) は、
# 負の長さの ${var:N:-M} と取り違えない (空の offset の ${x::-1} は表で拾う)
test_default_value_not_negative_length() {
  begin test_default_value_not_negative_length
  new_repo
  printf '#!/bin/bash\np="${2:-${PORT:-22}}"\n: "${T:=${D:-30}}"\necho "${p:+${T:-1}}" "${p:?${T:-1}}"\n' > "$r/d.sh"
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  end
}

# 対象外だったファイルを対象にしたら、もとからある目印と指示も足したものとして警告する (改名・shebang の追加)
test_untarget_to_target_warns() {
  begin test_untarget_to_target_warns
  new_repo
  printf '# notes\n# bash-compat: linux-only\n# shellcheck disable=SC2034\n' > "$r/notes.txt"
  printf '# bash-compat: linux-only\necho t\n' > "$r/tool"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" mv notes.txt deploy.sh
  printf 'declare -A m\n' >> "$r/deploy.sh" # bash-compat: ignore
  printf '#!/bin/bash\n# bash-compat: linux-only\necho t\n' > "$r/tool"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_out 'deploy.sh: warning'
  expect_out 'deploy.sh:3: warning'
  expect_out 'tool: warning'
  end
}

# 対象外のファイル (.command など) の shebang を bash に書き換えたら警告する
test_shebang_switched_to_bash_warns() {
  begin test_shebang_switched_to_bash_warns
  new_repo
  printf '#!/bin/zsh\necho a\n' > "$r/run.command"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/run.command" # bash-compat: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_out 'run.command: warning'
  end
}

# env のオプション (引数を取る -C dir なども) や変数の指定を挟んだ shebang、/bin/env、CRLF の shebang も bash として拾う。
# zsh は引数の位置によらず外す
test_env_shebang_variants() {
  begin test_env_shebang_variants
  new_repo
  printf '#!/usr/bin/env -S LC_ALL=C bash\necho "${x,,}"\n' > "$r/t1" # bash-compat: ignore
  printf '#!/usr/bin/env -i bash\necho "${x,,}"\n' > "$r/t2" # bash-compat: ignore
  printf '#!/bin/env bash\necho "${x,,}"\n' > "$r/t3" # bash-compat: ignore
  printf '#!/usr/bin/env -S zsh -f\ntypeset -A m\n' > "$r/z1" # bash-compat: ignore
  printf '#!/usr/bin/env -C /tmp bash\necho "${x,,}"\n' > "$r/t4" # bash-compat: ignore
  printf '#!/usr/bin/env --split-string=bash\necho "${x,,}"\n' > "$r/t5" # bash-compat: ignore
  # Windows で書いた CRLF のスクリプト
  printf '#!/bin/bash\r\necho "${x,,}"\r\n' > "$r/t6" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_out 't1:2: bash4-syntax'
  expect_out 't2:2: bash4-syntax'
  expect_out 't3:2: bash4-syntax'
  expect_out 't4:2: bash4-syntax'
  expect_out 't5:2: bash4-syntax'
  expect_out 't6:2: bash4-syntax'
  expect_no_out 'z1:'
  end
}

# 消したファイルの警告は後ろに出す (GitHub の注釈は 1 step に 10 件までで、先の警告で埋まらないように)
test_deleted_warnings_come_last() {
  begin test_deleted_warnings_come_last
  new_repo
  for n in 1 2 3; do printf '#!/bin/bash\necho %s\n' "$n" > "$r/d$n.sh"; done
  printf '#!/bin/bash\necho k\n' > "$r/k.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  git -C "$r" rm -q d1.sh d2.sh d3.sh
  printf '#!/bin/bash\n# bash-compat: linux-only\necho k\n' > "$r/k.sh"
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  first=$(printf '%s\n' "$out" | grep ': warning: ' | sed -n '1p')
  case "$first" in k.sh*) ;; *) fail_because "最初の警告が k.sh ではない: $first" ;; esac
  end
}

# 差分にあるのに作業ツリーに無いファイルは、黙って飛ばさず止める
test_missing_worktree_file_fails() {
  begin test_missing_worktree_file_fails
  new_repo
  printf 'x\n' > "$r/README"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\ndeclare -A m\n' > "$r/a.sh" # bash-compat: ignore
  commit "$r" head
  rm "$r/a.sh"
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 2
  expect_out '作業ツリーに無い'
  end
}

# 目印は行頭のコメントだけに効く。++ で始まる足した行も、差分の見出しと取り違えずに警告する
test_plusplus_lines() {
  begin test_plusplus_lines
  new_repo
  printf '#!/bin/bash\necho h\n' > "$r/h.sh"
  commit "$r" base
  base=$(git -C "$r" rev-parse HEAD)
  printf '#!/bin/bash\n: <<"X"\n++ # bash-compat: linux-only\n++ y=1 # bash-compat: ignore\nX\ndeclare -A m\n' > "$r/h.sh" # bash-compat: ignore
  commit "$r" head
  run_check "$r" "$base" "$(git -C "$r" rev-parse HEAD)"
  expect_rc 1
  expect_out 'h.sh:6: bash4-syntax'
  expect_out 'h.sh:4: warning'
  end
}

# NUL を含むなど binary に見えるファイルでも、bash 4 以降の構文を拾う
test_binary_looking_file() {
  begin test_binary_looking_file
  new_repo
  printf '#!/bin/bash\n# \000\ndeclare -A m\n' > "$r/f.sh" # bash-compat: ignore
  commit "$r" init
  run_check "$r" --all
  expect_rc 1
  expect_out 'f.sh:3: bash4-syntax'
  end
}

# source で読む隣のファイルが使う変数を、未使用 (SC2034) と言わない。source= の指示はスクリプトの場所から辿る
test_shellcheck_follows_source() {
  begin test_shellcheck_follows_source
  new_repo
  mkdir -p "$r/lib" "$r/bin"
  printf '#!/bin/bash\necho "$GREETING"\n' > "$r/lib/common.sh"
  printf '#!/bin/bash\nGREETING=hello\n# shellcheck source=../lib/common.sh\n. "$(dirname -- "$0")/../lib/common.sh"\n' > "$r/bin/main.sh"
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  expect_no_out 'SC2034'
  end
}

# Docker の初回はイメージの取得のメッセージが stderr に出る。版の判定に混ぜない
test_bash32_stderr_noise_ok() {
  begin test_bash32_stderr_noise_ok
  new_repo
  printf '#!/bin/bash\necho ok\n' > "$r/ok.sh"
  commit "$r" init
  if [ -n "$BASH32" ]; then
    printf '#!/bin/sh\necho "Pulling from library/bash" >&2\nexec "%s" "$@"\n' "$BASH32" > "$work/noisy-bash"
  else
    # Docker の経路では、check.sh と同じイメージの bash を前に雑音を出してから起動する
    image=$(sed -n "s/^IMAGE='\(.*\)'$/\1/p" "$check")
    printf '#!/bin/sh\necho "Pulling from library/bash" >&2\nexec docker run --rm -v "$PWD:/w:ro" -w /w "%s" bash "$@"\n' "$image" > "$work/noisy-bash"
  fi
  chmod +x "$work/noisy-bash"
  out=$(cd "$r" && BASH32="$work/noisy-bash" bash "$check" --all 2>&1)
  rc=$?
  expect_rc 0
  end
}

test_dotfiles_itself_clean() {
  begin test_dotfiles_itself_clean
  run_check "$repo_root" --all
  expect_rc 0
  end
}

test_bash4_syntax_table
test_bash32_parse_fails
test_extensionless_shebang
test_other_extension_skipped
test_zsh_skipped
test_comments_and_ignore
test_linux_only_marker
test_diff_checks_only_changed
test_three_dot_excludes_base_side
test_odd_names
test_missing_base_checks_all
test_head_missing_fails
test_head_not_checked_out_fails
test_weakening_changes_warn
test_gitattributes_cannot_hide_markers
test_shellcheck_directive_variants_warn
test_other_extension_shebang_added_warns
test_marker_moved_into_head_warns
test_literal_pathspec
test_deleted_target_warns
test_rename_keeps_markers_quiet
test_default_value_not_negative_length
test_untarget_to_target_warns
test_shebang_switched_to_bash_warns
test_env_shebang_variants
test_deleted_warnings_come_last
test_missing_worktree_file_fails
test_plusplus_lines
test_binary_looking_file
test_github_annotations
test_bash32_unavailable_fails
test_bash32_not_32_fails
test_shellcheck_follows_source
test_bash32_stderr_noise_ok
test_dotfiles_itself_clean

echo "passed: $passed, failed: $failed"
[ "$failed" = 0 ] || { echo "failed:$failed_names"; exit 1; }
