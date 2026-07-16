XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
ZDOTDIR=$XDG_CONFIG_HOME/zsh

# C415 ANTLR install
export ANTLR_INS="/home/chloe/builds/antlr/antlr4-install"

# C415 ANLTR generator
export ANTLR_JAR="$ANTLR_INS/bin/antlr-4.13.0-complete.jar"
export CLASSPATH="$ANTLR_JAR:$CLASSPATH"
alias antlr4="java -Xmx500M org.antlr.v4.Tool"
alias grun="java org.antlr.v4.gui.TestRig"
export MLIR_INS="/usr/lib/llvm-21/build"
export MLIR_DIR="$MLIR_INS/lib/cmake/mlir/" # Don't change me.

typeset -U path PATH
path=(~/.python_venv/bin ~/.local/bin ~/builds/neovim/install/bin ~/.cargo/bin $MLIR_DIR/bin $path)
export PATH

