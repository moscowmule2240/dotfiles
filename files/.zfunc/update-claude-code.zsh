#!/usr/bin/env zsh

update-claude-code() {
  brew update
  brew upgrade claude-code@latest
  brew cleanup -s
}
