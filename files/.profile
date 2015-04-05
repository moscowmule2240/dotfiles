PATH=$PATH:/usr/local/sbin

if [ -f /opt/local/etc/bash_completion ]; then
    . /opt/local/etc/bash_completion
fi

# .bashrc
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

