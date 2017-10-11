# bash_completion
[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion

# brew
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# ls
export LSCOLORS=gxfxcxdxbxegedabagacad

# MySQL
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"

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

# rbenv
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# pyenv
export PYENV_ROOT=/usr/local/var/pyenv
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# android
export ANDROID_SDK_ROOT=/usr/local/share/android-sdk

# mono
export MONO_GAC_PREFIX="/usr/local"

# zlib
export CFLAGS="-I$(xcrun --show-sdk-path)/usr/include $CFLAGS"

# readline
export CFLAGS="-I$(brew --prefix readline)/include $CFLAGS"
export LDFLAGS="-L$(brew --prefix readline)/lib $LDFLAGS"

# openssl
export CFLAGS="-I$(brew --prefix openssl)/include $CFLAGS"
export LDFLAGS="-L$(brew --prefix openssl)/lib $LDFLAGS"

# .bashrc
test -r ~/.bashrc && . ~/.bashrc

