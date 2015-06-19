# ls
alias ls='ls -G'
export LSCOLORS=gxfxcxdxbxegedabagacad

# history
HISTSIZE=102400
HISTTIMEFORMAT='%Y/%m/%d %H:%M:%S '

# bash_completion
source /usr/local/etc/bash_completion.d/*

# mysql
export PATH=$PATH:$HOME/opt/mysql/5.6.21/bin/
export DYLD_FALLBACK_LIBRARY_PATH=/usr/lib/:$HOME/opt/mysql/5.6.21/lib/:$DYLD_FALLBACK_LIBRARY_PATH

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

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
export PS1=' \[\033[32m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '

# ssh
alias ssh="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"
alias git="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;git"

# brew
alias brew-update="brew cleanup;brew update;brew upgrade brew-cask"
alias brew-cask-upgrade-all='for c in `brew cask list`; do ! brew cask info $c | grep -qF "Not installed" || brew cask install $c; done'
# brew download path
# /Library/Caches/Homebrew/

# alias
alias mysql-5.5.36='~/sandboxes/msb_5_6_16/stop; ~/sandboxes/msb_5_5_36/start'
alias mysql-5.5.36-restart='~/sandboxes/msb_5_5_36/stop; ~/sandboxes/msb_5_5_36/start'
alias mysql-5.6.21='~/sandboxes/msb_5_6_21/start'
alias mysql-5.6.21-restart='~/sandboxes/msb_5_6_21/stop; ~/sandboxes/msb_5_6_21/start'

alias redis-gree='redis-cli -p 16379 shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/gree.conf >/dev/null 2>&1 &'
alias redis-dgame='redis-cli shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/dgame.conf >/dev/null 2>&1 &'
alias redis-punk='redis-server ~/Workspace/dotfiles/conf/redis/punk.conf >/dev/null 2>&1 &'

alias enviroment='cd ~/Workspace/vagrant/'

# jenkins
alias punk-jenkins='java -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -jar /usr/local/opt/jenkins/libexec/jenkins.war'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc

# git
export PATH=/usr/local/bin:$PATH

