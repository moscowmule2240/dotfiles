# ls
alias ls='ls -G'

# history
HISTSIZE=102400
HISTTIMEFORMAT='%Y/%m/%d %H:%M:%S '

# bash_completion
source /usr/local/etc/bash_completion.d/*

# git
#GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=true
#GIT_PS1_DESCRIBE_STYLE=true
GIT_PS1_SHOWCOLORHINTS=true
source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
source /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash

# ssh
alias ssh="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"
alias git="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;git"

# brew
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi
alias brew-update="sudo chown -R $(whoami) /usr/local/bin; sudo chown -R $(whoami) /usr/local/share; sudo chown -R $(whoami) /usr/local/share/man; sudo chown -R $(whoami) /usr/local/share/man/man1; cd /usr/local/Library && git stash && git clean -d -f; brew update && brew upgrade brew-cask && brew cleanup && brew cask cleanup"
alias brew-cask-upgrade-all='for c in `brew cask list`; do ! brew cask info $c | grep -qF "Not installed" || brew cask install $c; done'
# brew download path
# /Library/Caches/Homebrew/

# visual studio code
code () {
    VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*
}

# alias
alias mysql-5.6.21='~/sandboxes/msb_5_6_21/start'
alias mysql-5.6.21-restart='~/sandboxes/msb_5_6_21/stop; ~/sandboxes/msb_5_6_21/start'

alias redis-app1='redis-cli -p 16379 shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/app1.conf >/dev/null 2>&1 &'
alias redis-app2='redis-cli -p 6379 shutdown >/dev/null 2>&1; redis-server ~/Workspace/dotfiles/conf/redis/app2.conf >/dev/null 2>&1 &'

alias enviroment='cd ~/Workspace/vagrant/'

# Search Unity Port
alias unity-port="lsof | grep Unity | grep TCP | grep LISTEN | awk '{print $9}' | cut -d ':' -f 2 | cut -d ' ' -f 1"

# jenkins
alias app2-jenkins='java -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -jar /usr/local/opt/jenkins/libexec/jenkins.war'

# Genymotion
alias genymotion-adb='/opt/homebrew-cask/Caskroom/genymotion/2.6.0/Genymotion.app/Contents/MacOS/tools/adb'
alias genymotion-screen-shot='genymotion-adb shell screencap -p /sdcard/Pictures/screenshot_`date "+%Y%m%d%H%M%S"`.png;genymotion-adb shell ls /sdcard/Pictures/* | tr "\r" " " | xargs -n 1 -I {} bash -ci "genymotion-adb pull {} ~/Pictures/genymotion/ > /dev/null";genymotion-adb shell rm /sdcard/Pictures/*'

# mine
. ~/Workspace/dotfiles/dotmine/bashrc

