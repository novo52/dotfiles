# Login shell. zsh is the shell; bash exists to hand over to it and to work as
# a fallback where zsh is absent.

# Some shared systems require environment from a site-wide profile that is not
# in /etc. A host overlay supplies this file where one is needed.
[ -r ~/.bash_profile_local ] && . ~/.bash_profile_local

# Interactive sessions go to zsh. The guard matters: without it, scp, rsync and
# `ssh host cmd` would also exec a login shell and break. NO_ZSH=1 is the way
# back in when zsh itself is the problem.
case $- in
  *i*) [ -z "$ZSH_VERSION" ] && [ -z "$NO_ZSH" ] && command -v zsh >/dev/null 2>&1 && exec zsh -l ;;
esac

[ -f ~/.bashrc ] && . ~/.bashrc
