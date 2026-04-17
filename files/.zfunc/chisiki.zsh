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

# chisiki-cli を mise で最新に更新し、バージョンが変わった場合のみバイナリに ad-hoc 署名を付与する
# （upstream リリースが未署名のため Apple Silicon カーネルに SIGKILL される対策）
chisiki-upgrade() {
  local tool="github:supermomonga/chisiki-cli"
  local install_dir="${HOME}/.local/share/mise/installs/github-supermomonga-chisiki-cli/latest"
  local bin="${install_dir}/chisiki"
  local before after
  before=$(mise ls --current "${tool}" 2>/dev/null | awk 'NR==1 {print $2}')
  mise upgrade "${tool}" || return $?
  after=$(mise ls --current "${tool}" 2>/dev/null | awk 'NR==1 {print $2}')
  if [[ -n "${before}" && "${before}" == "${after}" ]]; then
    echo "chisiki already up to date: ${after}"
    return 0
  fi
  if [[ ! -x "${bin}" ]]; then
    echo "chisiki-upgrade: binary not found at ${bin}" >&2
    return 1
  fi
  codesign --remove-signature "${bin}" 2>/dev/null
  codesign --force --sign - "${bin}" || return $?
  mise reshim
  echo "chisiki upgraded to ${after} and signed ad-hoc"
}
