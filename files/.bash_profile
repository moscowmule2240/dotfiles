# bash_completion
[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion

# pyenv
export PYENV_ROOT=/usr/local/var/pyenv
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# console
function updatePrompt {

    # Styles
    GREEN='\[\e[0;32m\]'
    BLUE='\[\e[0;34m\]'
    RESET='\[\e[0m\]'

    # Base prompt: \W = working dir
    PROMPT="\W"

    # Current Git repo
    if type "__git_ps1" > /dev/null 2>&1; then
        PROMPT="$PROMPT$(__git_ps1 "${GREEN} (%s)${RESET}")"
    fi

    # Current virtualenv
    if [[ $VIRTUAL_ENV != "" ]]; then
        # Strip out the path and just leave the env name
        PROMPT="(${VIRTUAL_ENV##*/}) ${RESET}$PROMPT"
    fi

    PS1="$PROMPT\$ "
}
export -f updatePrompt

# Bash shell executes this function just before displaying the PS1 variable
export PROMPT_COMMAND='updatePrompt'

# .bashrc
test -r ~/.bashrc && . ~/.bashrc

