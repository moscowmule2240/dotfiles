# path
export PATH=$PATH:/usr/local/sbin:~/Workspace/dotfiles/files/bin

# .bashrc
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

# pyenv
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# mine
. ~/Workspace/dotfiles/dotmine/profile

