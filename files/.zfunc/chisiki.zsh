#!/usr/bin/env zsh
# chisiki-cli セッションヘルパー

chisiki-unlock() {
  export BW_SESSION=${BW_SESSION:-$(bw unlock --raw)}
  # GUI / Web で追加した item を CLI 側に取り込むため毎回 sync
  bw sync >/dev/null
  export CHISIKI_MASTER_PASSWORD=$(bw get password chisiki-secretkey)
  local delivery_key
  delivery_key=$(bw get password chisiki-delivery-key 2>/dev/null | tr -d '[:space:]')
  if [[ -n "$delivery_key" ]]; then
    export CHISIKI_DELIVERY_PRIVATE_KEY=$delivery_key
    echo "chisiki unlocked (master pw=${#CHISIKI_MASTER_PASSWORD}c, delivery key set)"
  else
    echo "chisiki unlocked (master pw=${#CHISIKI_MASTER_PASSWORD}c, delivery key NOT in bw)"
    echo "  → bw に Item 'chisiki-delivery-key' を作成後に再 unlock"
  fi
}

chisiki-lock() {
  unset CHISIKI_MASTER_PASSWORD CHISIKI_DELIVERY_PRIVATE_KEY BW_SESSION
  echo "chisiki locked"
}
