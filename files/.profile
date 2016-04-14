# path
export PATH=$PATH:/usr/local/sbin:~/Workspace/dotfiles/files/bin

# ls
export LSCOLORS=gxfxcxdxbxegedabagacad

# git
export PATH=/usr/local/bin:$PATH
export PS1=' \[\033[32m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '

# pyenv
export PYENV_ROOT="${HOME}/.pyenv"
if [ -d "${PYENV_ROOT}" ]; then
    export PATH=${PYENV_ROOT}/bin:$PATH
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# mysql
export PATH=$PATH:$HOME/opt/mysql/5.6.21/bin
export DYLD_FALLBACK_LIBRARY_PATH=/usr/lib/:$HOME/opt/mysql/5.6.21/lib/:$DYLD_FALLBACK_LIBRARY_PATH

# mine
. ~/Workspace/dotfiles/dotmine/profile

# .bashrc
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

