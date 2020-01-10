# bashrc
. ~/Workspace/dotfiles/files/bashrc

alias open="cmd.exe /c start"
alias documents="cd /d/Documents"
alias downloads="cd /d/Downloads"
alias workspace="cd ~/Workspace"

# ssh
concat_ssh_config="cat ~/.ssh/conf.d/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config"
eval ${concat_ssh_config}
alias ssh="eval ${concat_ssh_config};ssh"
alias scp="eval ${concat_ssh_config};scp"

# mine
. ~/Workspace/dotfiles/dotmine/files/windows/bashrc
