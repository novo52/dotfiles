# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/chloe/.zshrc'

autoload -Uz compinit 
compinit
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
export GTK_THEME=Adwaita:dark

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

source $HOME/.config/zsh/.zsh_aliases
source $ZSH/oh-my-zsh.sh
