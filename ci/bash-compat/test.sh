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

if [ -z "${BASH32:-}" ] && /bin/bash -c '[ "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}" = 3.2 ]' 2>/dev/null; then
  BASH32=/bin/bash
fi
export BASH32="${BASH32:-}"

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

# check.sh を $1 のディレクトリで流し、出力を $out、終了コードを $rc に入れる
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

test_clean_passes() {
  begin test_clean_passes
  new_repo
  printf '#!/bin/bash\necho "$1"\n' > "$r/ok.sh"
  commit "$r" init
  run_check "$r" --all
  expect_rc 0
  end
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
  expect_no_out 'gone.sh'
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
  printf '#!/bin/sh\necho "Pulling from library/bash" >&2\nexec "%s" "$@"\n' "$BASH32" > "$work/noisy-bash"
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

test_clean_passes
test_bash4_syntax_table
test_bash32_parse_fails
test_extensionless_shebang
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
test_github_annotations
test_bash32_unavailable_fails
test_bash32_not_32_fails
test_shellcheck_follows_source
test_bash32_stderr_noise_ok
test_dotfiles_itself_clean

echo "passed: $passed, failed: $failed"
[ "$failed" = 0 ] || { echo "failed:$failed_names"; exit 1; }
