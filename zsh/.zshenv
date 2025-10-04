typeset -U path PATH
path=(~/.python_venv/bin ~/.local/bin $path)
export PATH

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
ZDOTDIR=$XDG_CONFIG_HOME/zsh


ANTLR_INS="$HOME/builds/antlr/antlr4-install"
ANTLR_JAR="$ANTLR_INS/bin/antlr-4.13.0-complete.jar"
export ANTLR_INS ANTLR_JAR
CLASSPATH="$ANTLR_JAR:$CLASSPATH"
antlr4="java -Xmx500M org.antlr.v4.Tool"
grun='java org.antlr.v4.gui.TestRig'
MLIR_INS="/home/chloe/builds/llvm-project/build"
MLIR_DIR="$MLIR_INS/lib/cmake/mlir/"
PATH="$MLIR_INS/bin:$PATH"


#ANTLR_INS=/home/chloe/builds/antlr/antlr4-install;
#ANTLR_JAR=/home/chloe/builds/antlr/antlr4-install/bin/antlr-4.13.0-complete.jar;
