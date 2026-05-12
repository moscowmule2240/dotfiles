#!/bin/sh
# Bitwarden SSH agent ソケットを必ず指定した上で ssh-add に委譲する。
# git の gpg.ssh.defaultKeyCommand から呼ばれる ssh-add が
# SSH_AUTH_SOCK 未設定 / 別 socket 固定で失敗するのを防ぐためのラッパ。
SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock" exec /usr/bin/ssh-add "$@"
