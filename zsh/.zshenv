typeset -U path PATH
path=(~/.python_venv/bin ~/.local/bin ~/builds/neovim/install/bin ~/.cargo/bin $path)
export PATH

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
ZDOTDIR=$XDG_CONFIG_HOME/zsh
