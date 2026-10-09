# Lines configured by zsh-newuser-install
# oh-my-zsh raises HISTSIZE to 50000 and SAVEHIST to 10000 when they are lower,
# so a smaller value here has no effect. It also sets share_history, under which
# every write trims the file to SAVEHIST -- that is the setting which bounds how
# much history survives.
HISTFILE=~/.histfile
HISTSIZE=200000
SAVEHIST=200000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$ZDOTDIR/.zshrc"

# The dump is keyed on host and zsh version and kept in the cache directory:
# $ZDOTDIR is a stow package inside a git repo, and on a shared NFS home every
# workstation writes its own dump.
ZSH_COMPDUMP=$HOME/.cache/zsh/zcompdump-${HOST%%.*}-$ZSH_VERSION
mkdir -p $HOME/.cache/zsh
autoload -Uz compinit
compinit -d $ZSH_COMPDUMP
# End of lines added by compinstall

export EDITOR=nvim
export VISUAL=nvim

# oh-my-zsh
export ZSH=~/.oh-my-zsh
ZSH_THEME="robbyrussell"
ENABLE_CORRECTION="true"
plugins=(git zsh-vi-mode)
export LANG=en_CA.UTF-8

# vi-mode
ZVM_VI_INSERT_ESCAPE_BINDKEY=kj
ZVM_VI_VISUAL_ESCAPE_BINDKEY=kj
bindkey -a -r ':' # disable "execute: "

# Color
#export CLICOLOR=1
#export LSCOLORS=GxFxCxDxBxegedabagaced
#autoload -U colors && colors
#PS1="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[cyan]%}%1~%{$reset_color%} %% "

set +o noclobber 
setopt EXTENDED_GLOB


export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# fnm (Node). Only the laptop has it.
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir -p $ZSH_CACHE_DIR
fi

source $ZDOTDIR/.zsh_aliases
source $ZSH/oh-my-zsh.sh

# This machine's interactive configuration, then anything untracked. Both come
# last so they can override the shared configuration and oh-my-zsh alike.
[[ -r $XDG_CONFIG_HOME/host/zsh/host.zsh ]] && source $XDG_CONFIG_HOME/host/zsh/host.zsh
[[ -r $XDG_CONFIG_HOME/host/zsh/local.zsh ]] && source $XDG_CONFIG_HOME/host/zsh/local.zsh
