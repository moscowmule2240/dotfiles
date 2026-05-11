#!/usr/bin/env zsh

update-claude() {
  brew update
  brew upgrade claude claude-code@latest
  brew cleanup -s
}
