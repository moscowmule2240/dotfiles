# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# zsh
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ls
autoload -U compinit
compinit
export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

# Homebrew
if [ "$(uname)" = 'Darwin' ]; then
    # Apple Silicon
    if [ "$(uname -m)" = 'arm64' ]; then
        eval $(/opt/homebrew/bin/brew shellenv)
    else
        eval $(/usr/local/bin/brew shellenv)
    fi
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# liquidprompt
if [ -f $(brew --prefix)/share/liquidprompt ]; then
    . $(brew --prefix)/share/liquidprompt
fi

# zsh-completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# zsh-git-prompt
. "$(brew --prefix zsh-git-prompt)/zshrc.sh"

# less
export LESS=' -X -R -F '
export LESSOPEN='| $(brew --prefix)/bin/src-hilite-lesspipe.sh %s'

# history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_verify
setopt hist_reduce_blanks
setopt hist_no_store

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

# direnv
export DIRENV_WARN_TIMEOUT=100s
export EDITOR=vim
eval "$(asdf exec direnv hook zsh)"

# android
export ANDROID_SDK_ROOT=$(brew --prefix)/share/android-sdk
export PATH="${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# coreutils
export PATH="$PATH:$(brew --prefix coreutils)/libexec/gnubin"

# mysql
export PATH="$(brew --prefix mysql-client)/bin:$PATH"

# elixir
export MANPATH=$(brew --prefix erlang)/lib/erlang/man:$MANPATH

# mono
export MONO_GAC_PREFIX=$(brew --prefix)

# docker
export COMPOSE_HTTP_TIMEOUT=300

# python install
BREW_FORMULAE_MYSQL="mysql-client@8.0"
export LDFLAGS="-L$(brew --prefix libffi)/lib -L$(brew --prefix zlib)/lib -L$(brew --prefix bzip2)/lib -L$(brew --prefix sqlite)/lib -L$(brew --prefix zstd)/lib -L$(brew --prefix openssl)/lib -L$(brew --prefix ${BREW_FORMULAE_MYSQL})/lib"
export CPPFLAGS="-I$(brew --prefix libffi)/include -I$(brew --prefix zlib)/include -I$(brew --prefix bzip2)/include -I$(brew --prefix sqlite)/include -I$(brew --prefix zstd)/include -I$(brew --prefix openssl)/include -I$(brew --prefix ${BREW_FORMULAE_MYSQL})/include"
export CONFIGURE_OPTS="--with-openssl=$(brew --prefix openssl)"
export PKG_CONFIG_PATH="$(brew --prefix ${BREW_FORMULAE_MYSQL})/lib/pkgconfig"
MYSQL_VERSION=`ls -la $(brew --prefix ${BREW_FORMULAE_MYSQL}) | awk '{print $11}' | awk -F "/" '{print $4}'`
export MYSQLCLIENT_LDFLAGS="-L${HOMEBREW_CELLAR}/${BREW_FORMULAE_MYSQL}/${MYSQL_VERSION}/lib -lmysqlclient"
export MYSQLCLIENT_CFLAGS="-I${HOMEBREW_CELLAR}/${BREW_FORMULAE_MYSQL}/${MYSQL_VERSION}/include/mysql"

