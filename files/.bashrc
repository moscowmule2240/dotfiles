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

# brew
alias brew-cask-update='for c in `brew cask list`; do ! brew cask info $c | grep -qF "Not installed" || brew cask uninstall $c --force && brew cask install $c; done'

# brew file
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi

# alias
alias mysqld-app1='docker start mysqld-app1'
alias mysqld-app2='docker start mysqld-app2'

alias redis-app1='docker start redis-app1'
alias redis-app2='docker start redis-app2'

# Search Unity Port
alias unity-port="lsof | grep Unity | grep TCP | grep LISTEN | awk '{print $9}' | cut -d ':' -f 2 | cut -d ' ' -f 1"

# jenkins
alias punk-jenkins='java -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -jar /usr/local/opt/jenkins/libexec/jenkins.war'

# Genymotion
alias genymotion-adb='/opt/homebrew-cask/Caskroom/genymotion/2.6.0/Genymotion.app/Contents/MacOS/tools/adb'
alias genymotion-screen-shot='genymotion-adb shell screencap -p /sdcard/Pictures/screenshot_`date "+%Y%m%d%H%M%S"`.png;genymotion-adb shell ls /sdcard/Pictures/* | tr "\r" " " | xargs -n 1 -I {} bash -ci "genymotion-adb pull {} ~/Pictures/genymotion/ > /dev/null";genymotion-adb shell rm /sdcard/Pictures/*'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc
