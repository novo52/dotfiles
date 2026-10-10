# Login shell. zsh is the shell; bash exists to hand over to it and to work as
# a fallback where zsh is absent.

# Some shared systems require environment from a site-wide profile that is not
# in /etc. A host overlay supplies this file where one is needed.
[ -r ~/.bash_profile_local ] && . ~/.bash_profile_local

# On a machine without a system zsh, the bootstrap puts one in ~/.local/bin,
# which has to be on PATH before the check below can find it.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH=$HOME/.local/bin:$PATH ;;
esac

# Interactive sessions go to zsh. The guard matters: without it, scp, rsync and
# `ssh host cmd` would also exec a login shell and break.
#
# NO_ZSH=1 is the way back in when zsh itself is the problem. ssh does not
# forward the variable, so set it on the remote side:
#   ssh -t host 'NO_ZSH=1 bash -l'
case $- in
  *i*) [ -z "$ZSH_VERSION" ] && [ -z "$NO_ZSH" ] && command -v zsh >/dev/null 2>&1 && exec zsh -l ;;
esac

# bash reads ~/.profile only when this file is absent, so read it here: it is
# where a distro or an installer puts PATH entries. The stock one sources
# ~/.bashrc itself.
if [ -r ~/.profile ]; then
  . ~/.profile
elif [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
