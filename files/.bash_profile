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

# console
function updatePrompt {

    # Styles
    GREEN='\[\e[0;32m\]'
    BLUE='\[\e[0;34m\]'
    RED='\[\e[0;31m\]'
    LIGHT_RED='\[\e[1;31m\]'
    YELLOW='\[\e[1;33m\]'
    RESET='\[\e[0m\]'

    # Base prompt: \W = working dir
    PROMPT="\W"

    # Current Git repo
    if type "__git_ps1" > /dev/null 2>&1; then
        PROMPT="${YELLOW}$PROMPT${RESET}$(__git_ps1 "${GREEN} (%s)${RESET}")"
    fi

    # Current virtualenv
    if [[ $VIRTUAL_ENV != "" ]]; then
        # Strip out the path and just leave the env name
        PROMPT="${BLUE}(${VIRTUAL_ENV##*/}) ${RESET}$PROMPT"
    fi

    PS1="$PROMPT\$ "
}
export -f updatePrompt

# Bash shell executes this function just before displaying the PS1 variable
export PROMPT_COMMAND='updatePrompt'

# asdf
. $(brew --prefix asdf)/asdf.sh

# .bashrc
test -r ~/.bashrc && . ~/.bashrc

