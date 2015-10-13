# path
export PATH=$PATH:/usr/local/sbin

# homebrew
export HOMEBREW_GITHUB_API_TOKEN=5e7689b195b73415efb0ec11d67402899de4cc5d

# go
export GOPATH=~/Workspace/go/.go
export PATH=$GOPATH/bin:$PATH

# .net
source dnvm.sh

# .bashrc
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

