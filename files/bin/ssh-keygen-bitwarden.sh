#!/bin/sh
# Bitwarden SSH agent ソケットを必ず指定した上で ssh-keygen に委譲する。
# Claude Desktop など SSH_AUTH_SOCK が macOS 標準 ssh-agent socket に
# 固定される環境下でも git の SSH 署名が通るようにするためのラッパ。
SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock" exec /usr/bin/ssh-keygen "$@"
