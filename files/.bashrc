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

# brew
alias brew-cask-update='for c in `brew cask list`; do ! brew cask info $c | grep -qF "Not installed" || brew cask uninstall $c --force && brew cask install $c; done'

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

alias stop_middleware="docker ps -q | xargs docker stop"

# node
NODEBREW_HOME=/usr/local/var/nodebrew/current
export NODEBREW_HOME
export NODEBREW_ROOT=/usr/local/var/nodebrew
export PATH=$NODEBREW_HOME/bin:$PATH

# mine
. ~/Workspace/dotfiles/dotmine/bashrc

