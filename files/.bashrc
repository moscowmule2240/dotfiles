# ls
alias ls='ls -G'
export LSCOLORS=gxfxcxdxbxegedabagacad

# mysql
export PATH=$PATH:$HOME/opt/mysql/5.5.36/bin/
export DYLD_FALLBACK_LIBRARY_PATH=$HOME/opt/mysql/5.5.36/lib/:$DYLD_FALLBACK_LIBRARY_PATH

# pyenv
eval "$(pyenv init -)"

# python
__pyenv_ps1 ()
{
  local version_string=$(pyenv version | cut -d ' ' -f 1)
  printf "($version_string) "
}

# go
export PATH=$PATH:/usr/local/opt/go/libexec/bin

# git
#GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=true
#GIT_PS1_DESCRIBE_STYLE=true
GIT_PS1_SHOWCOLORHINTS=true
source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
source /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
export PS1='\[\033[34m\]$(__pyenv_ps1)\[\033[32m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '

# ssh
alias ssh="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"
alias git="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;git"

# alias
alias mysql-5.5.36='~/sandboxes/msb_5_6_16/stop; ~/sandboxes/msb_5_5_36/start'
alias mysql-5.6.16='~/sandboxes/msb_5_5_36/stop; ~/sandboxes/msb_5_6_16/start'

alias redis-app1='redis-cli -p 16379 shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/app1.conf >/dev/null 2>&1 &'
alias redis-app2='redis-cli shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/app2.conf >/dev/null 2>&1 &'

alias enviroment='cd ~/Workspace/vagrant/'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc

