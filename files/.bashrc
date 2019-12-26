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

# libralies
export LDFLAGS="-L/usr/local/opt/readline/lib"
export CPPFLAGS="-I/usr/local/opt/readline/include"
export PKG_CONFIG_PATH="/usr/local/opt/readline/lib/pkgconfig"

# brew file
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi

# middleware
function add_middleware () {
    name=${1}
    app=${2}
    count=${3}

    for i in `seq 1 ${count}`
    do
        container=${name}-${app}-${i}
        alias ${container}="docker start ${container}"
    done
}

add_middleware mysqld app1 4
add_middleware mysqld app2 4
add_middleware redis app1 1
add_middleware redis app2 1

# docker
alias kill-docker-all='if [ -n "`docker ps -q`" ]; then docker kill `docker ps -q`; fi'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc

