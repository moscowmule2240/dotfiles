# bash_completion
[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion

# ls
export LSCOLORS=gxfxcxdxbxegedabagacad

# MySQL
export PATH=$PATH:$HOME/opt/mysql/5.6.21/bin
export DYLD_FALLBACK_LIBRARY_PATH=/usr/lib/:$HOME/opt/mysql/5.6.21/lib/:$DYLD_FALLBACK_LIBRARY_PATH

# pyenv
export PYENV_ROOT=/usr/local/var/pyenv
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

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

# .bashrc
test -r ~/.bashrc && . ~/.bashrc

