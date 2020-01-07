# ls
alias ls='ls -G'

# history
HISTSIZE=102400
HISTTIMEFORMAT='%Y/%m/%d %H:%M:%S '

# git
#GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=true
#GIT_PS1_DESCRIBE_STYLE=true
GIT_PS1_SHOWCOLORHINTS=true

# ssh
alias ssh="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"
alias git="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;git"

# docker
alias kill-docker-all='if [ -n "`docker ps -q`" ]; then docker kill `docker ps -q`; fi'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc
