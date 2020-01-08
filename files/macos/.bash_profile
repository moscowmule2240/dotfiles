# brew
eval $(brew shellenv)

# bash_completion
if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "$COMPLETION"
    done
  fi
fi

# ls
export LSCOLORS=gxfxcxdxbxegedabagacad

# android
export ANDROID_SDK_ROOT=/usr/local/share/android-sdk

# mono
export MONO_GAC_PREFIX="/usr/local"

# gettext
# For compilers to find gettext you may need to set:
#  export LDFLAGS="-L/usr/local/opt/gettext/lib"
#  export CPPFLAGS="-I/usr/local/opt/gettext/include"

# ncurses
# For compilers to find ncurses you may need to set:
#  export LDFLAGS="-L/usr/local/opt/ncurses/lib"
#  export CPPFLAGS="-I/usr/local/opt/ncurses/include"

# openssl@1,1
# For compilers to find openssl@1.1 you may need to set:
#  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
#  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"

# protobuf@3.7
# For compilers to find protobuf@3.7 you may need to set:
#  export LDFLAGS="-L/usr/local/opt/protobuf@3.7/lib"
#  export CPPFLAGS="-I/usr/local/opt/protobuf@3.7/include"

# readline
# For compilers to find readline you may need to set:
#  export LDFLAGS="-L/usr/local/opt/readline/lib"
#  export CPPFLAGS="-I/usr/local/opt/readline/include"

# android
export PATH="${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# coreutils
export PATH="$PATH:${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"

# mysql
export PATH="${HOMEBREW_PREFIX}/opt/mysql-client/bin:$PATH"

# elixir
export MANPATH=${HOMEBREW_PREFIX}/opt/erlang/lib/erlang/man:$MANPATH

# pyenv
eval "$(pyenv init -)"

# pipenv
export PIPENV_IGNORE_VIRTUALENVS=1
eval "$(pipenv --completion)"

# direnv
export EDITOR=vim
eval "$(direnv hook bash)"

# asdf
. $(brew --prefix asdf)/asdf.sh

# git
if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

# .bashrc
test -r ~/.bashrc && . ~/.bashrc
