# ls
alias ls='ls -G'

# ssh
alias ssh="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;ssh"
alias scp="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;scp"
alias git="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config;git"

# bashrc
. ~/Workspace/dotfiles/files/bashrc

# mine
. ~/Workspace/dotfiles/dotmine/files/macos/bashrc
