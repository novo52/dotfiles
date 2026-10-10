#!/bin/sh
# Checks a bootstrapped home from the outside, the way a person arriving at the
# machine would meet it: through a login shell. Run by inside.sh.

set -u
FAILED=0
TOOLS=$HOME/dotfiles/bootstrap/tools.tsv
LOCK=$HOME/dotfiles/bootstrap/conda-linux-64.lock

pass() { printf 'PASS: %s\n' "$*"; }
fail() {
  printf 'FAIL: %s\n' "$*"
  FAILED=1
}
expect() { # expect <description> <actual> <pattern>
  case $2 in
    $3) pass "$1 ($2)" ;;
    *) fail "$1: got '$2', wanted $3" ;;
  esac
}

# A command as an interactive zsh sees it, which is where PATH is complete.
in_zsh() { bash -lc "zsh -ic '$1'" 2> /dev/null < /dev/null; }

# --- shells
expect "non-interactive login bash stays bash" "$(bash -lc 'echo "bash-$BASH_VERSION"' < /dev/null 2>&1)" 'bash-[0-9]*'
if command -v script > /dev/null 2>&1; then
  reached=$(printf 'echo REACHED=$ZSH_VERSION\nexit\n' | script -qec 'bash -l' /dev/null 2>&1 | tr -d '\r' | grep -o 'REACHED=[0-9.]*' | tail -n 1)
  expect "interactive login bash hands over to zsh" "$reached" 'REACHED=5.*'
else
  fail "no 'script' command to allocate a terminal with"
fi
expect "interactive zsh starts without messages" "$(bash -lc 'zsh -ic true' 2>&1 < /dev/null)" ''

# --- links, and the skeleton file that stood in the way
for f in .zshenv .bashrc .bash_profile .gitconfig .tmux.conf .config/zsh/.zshrc .config/nvim/init.lua; do
  [ -L "$HOME/$f" ] && pass "~/$f is a link" || fail "~/$f is not a link"
done
if ls "$HOME"/.local/share/dotfiles-backups/*/.bashrc > /dev/null 2>&1; then
  pass "the skeleton .bashrc was kept in the backup directory"
else
  fail "the skeleton .bashrc was not backed up"
fi

# --- pinned versions
pin() { sed -n "s|.*/$1-\([0-9][0-9.]*\)-.*|\1|p" "$LOCK"; }
expect "nvim" "$(in_zsh 'nvim --version' | head -n 1)" "NVIM v$(awk -F '\t' '$1 == "nvim" { print $3 }' "$TOOLS")"
expect "tree-sitter" "$(in_zsh 'tree-sitter --version')" "*$(pin tree-sitter-cli)*"
expect "rg" "$(in_zsh 'rg --version' | head -n 1)" "*$(pin ripgrep)*"
expect "fd" "$(in_zsh 'fd --version')" "*$(pin fd-find)*"
expect "fzf" "$(in_zsh 'fzf --version')" "$(pin fzf | cut -d. -f1,2)*"
for b in git stow; do
  expect "$b runs" "$(in_zsh "$b --version" | head -n 1)" '?*'
done

# --- nvim
plugins=$(in_zsh 'nvim --headless "+lua io.stdout:write(#require([[lazy]]).plugins())" +qa' | tr -dc '0-9')
locked=$(grep -c '"branch"' "$HOME/dotfiles/nvim/.config/nvim/lazy-lock.json")
if [ "${plugins:-0}" -ge 20 ] && [ "${plugins:-0}" -le "$locked" ]; then
  pass "nvim loads $plugins plugins ($locked locked)"
else
  fail "nvim reports '${plugins:-}' plugins against $locked locked"
fi

start=$(bash -lc "zsh -ic 'nvim --headless \"+sleep 2\" +qa'" 2>&1 < /dev/null | tr -d '\r')
parsers=$(in_zsh 'nvim --headless "+lua io.stdout:write(#require([[nvim-treesitter]]).get_installed())" +qa' | tr -dc '0-9')
# Parsers need a compiler to build. A machine without one has them only when
# another machine sharing the home built them.
if [ "${parsers:-0}" -ge 13 ]; then
  pass "$parsers treesitter parsers present"
  expect "nvim starts without messages" "$start" ''
elif bash -lc "zsh -ic 'command -v cc || command -v gcc'" > /dev/null 2>&1; then
  fail "only '${parsers:-}' treesitter parsers, with a compiler present"
else
  expect "nvim says parsers need a compiler" "$start" '*C compiler*'
fi

# --- the bootstrap's own verification, through its installed name
if in_zsh 'dots verify' > /tmp/dots-verify 2>&1; then
  pass "dots verify"
else
  fail "dots verify"
  sed 's/^/  | /' /tmp/dots-verify
fi

exit $FAILED
