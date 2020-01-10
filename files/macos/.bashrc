# bashrc
. ~/Workspace/dotfiles/files/bashrc

# ls
export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls='ls -G'

# less
export LESS="--no-init --quit-if-one-screen --raw-control-chars"
export LESSOPEN='| /usr/local/bin/src-hilite-lesspipe.sh %s'

# android
export ANDROID_SDK_ROOT=/usr/local/share/android-sdk

# mono
export MONO_GAC_PREFIX="/usr/local"

# gettext
# For compilers to find gettext you may need to set:
#  export LDFLAGS="-L/usr/local/opt/gettext/lib"
#  export CPPFLAGS="-I/usr/local/opt/gettext/include"

# ncurses
# For compilers to find ncurses you may need to set:
#  export LDFLAGS="-L/usr/local/opt/ncurses/lib"
#  export CPPFLAGS="-I/usr/local/opt/ncurses/include"

# openssl@1,1
# For compilers to find openssl@1.1 you may need to set:
#  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
#  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"

# protobuf@3.7
# For compilers to find protobuf@3.7 you may need to set:
#  export LDFLAGS="-L/usr/local/opt/protobuf@3.7/lib"
#  export CPPFLAGS="-I/usr/local/opt/protobuf@3.7/include"

# readline
# For compilers to find readline you may need to set:
#  export LDFLAGS="-L/usr/local/opt/readline/lib"
#  export CPPFLAGS="-I/usr/local/opt/readline/include"

# direnv
export EDITOR=vim
eval "$(direnv hook bash)"

# git
if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

# ssh
concat_ssh_config="cat ~/.ssh/conf.d/config ~/.ssh/conf.d/macos/config ~/Workspace/dotfiles/dotmine/ssh/config > ~/.ssh/config"
eval ${concat_ssh_config}
alias ssh="eval ${concat_ssh_config};ssh"
alias scp="eval ${concat_ssh_config};scp"

# mine
. ~/Workspace/dotfiles/dotmine/files/macos/bashrc
