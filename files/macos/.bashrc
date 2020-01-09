# ls
alias ls='ls -G'

# ssh
cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config
alias ssh="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"

# bashrc
. ~/Workspace/dotfiles/files/bashrc

# mine
. ~/Workspace/dotfiles/dotmine/files/macos/bashrc
