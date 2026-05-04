#!/usr/bin/env zsh
# chisiki-cli セッションヘルパー

chisiki-unlock() {
  export BW_SESSION=${BW_SESSION:-$(bw unlock --raw)}
  export CHISIKI_MASTER_PASSWORD=$(bw get password chisiki-secretkey)
  echo "chisiki unlocked (master pw length=${#CHISIKI_MASTER_PASSWORD})"
}

chisiki-lock() {
  unset CHISIKI_MASTER_PASSWORD BW_SESSION
  echo "chisiki locked"
}
