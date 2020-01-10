# brew
eval $(brew shellenv)

# bash_completion
if type brew &>/dev/null; then
  if [[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]]; then
    source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "$(brew --prefix)/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "${COMPLETION}"
    done
  fi
fi

# android
export PATH="${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# coreutils
export PATH="$PATH:${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"

# mysql
export PATH="${HOMEBREW_PREFIX}/opt/mysql-client/bin:$PATH"

# elixir
export MANPATH=${HOMEBREW_PREFIX}/opt/erlang/lib/erlang/man:$MANPATH

# asdf
. $(brew --prefix asdf)/asdf.sh

# .bashrc
test -r ~/.bashrc && . ~/.bashrc
