# path
export PATH=$PATH:/usr/local/sbin

# go
export GOPATH=~/Workspace/go/.go
export PATH=$GOPATH/bin:$PATH

if [ -f /opt/local/etc/bash_completion ]; then
    . /opt/local/etc/bash_completion
fi

# .bashrc
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

