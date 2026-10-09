XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
ZDOTDIR=$XDG_CONFIG_HOME/zsh

typeset -U path PATH
path=(~/.local/bin $path)
export PATH

# Environment belonging to this machine alone: PATH entries for toolchains
# installed outside the package manager, and the variables they need. Stowed
# from the machine's overlay package; absent on a machine without one.
[[ -r $XDG_CONFIG_HOME/host/zsh/host.env.zsh ]] && source $XDG_CONFIG_HOME/host/zsh/host.env.zsh
