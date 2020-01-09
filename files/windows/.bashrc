alias open="cmd.exe /c start"
alias documents="cd /d/Documents"
alias downloads="cd /d/Downloads"
alias workspace="cd ~/Workspace"

# ssh
cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config
alias ssh="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"

# bashrc
. ~/Workspace/dotfiles/files/bashrc

# mine
. ~/Workspace/dotfiles/dotmine/files/windows/bashrc
