typeset -U path PATH
path=(~/.local/bin $path)
export PATH

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
ZDOTDIR=$XDG_CONFIG_HOME/zsh

