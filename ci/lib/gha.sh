#!/bin/bash
# GitHub Actions の注釈の値をエスケープする共通関数。
# 呼び出し元 (ci/katakana・ci/bash-compat) がそれぞれ checkout した配下の ../lib/gha.sh から source する。
# 値は % と改行、プロパティはさらに : と , をエスケープする。
esc_data() {
  local s=$1
  s=${s//"%"/%25}
  s=${s//$'\r'/%0D}
  s=${s//$'\n'/%0A}
  printf '%s' "$s"
}

esc_prop() {
  local s
  s=$(esc_data "$1")
  s=${s//":"/%3A}
  s=${s//","/%2C}
  printf '%s' "$s"
}
