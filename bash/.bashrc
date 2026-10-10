# Reached only when zsh is unavailable, or when something invokes bash
# directly. Deliberately minimal: zsh carries the real configuration.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export EDITOR=nvim
export VISUAL=nvim
command -v nvim >/dev/null 2>&1 || { export EDITOR=vi; export VISUAL=vi; }

HISTCONTROL=ignoreboth
HISTSIZE=200000
HISTFILESIZE=200000
shopt -s histappend
shopt -s checkwinsize

bind 'set completion-ignore-case on'
set +o noclobber

if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto --file-type -hN'
    alias grep='grep --color=auto'
fi

case "$TERM" in
    *-256color|xterm-color) PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ ';;
    *) PS1='\u@\h:\w\$ ';;
esac

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Untracked, for anything that must not reach a repo. Mirrors the role of
# ~/.config/host/zsh/local.zsh.
if [ -f ~/.bash_system_specific ]; then
    . ~/.bash_system_specific
fi
