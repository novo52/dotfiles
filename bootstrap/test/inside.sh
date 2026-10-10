#!/bin/sh
# Runs inside a test container, as the unprivileged user. See run.sh.
#
#   inside.sh full     bootstrap twice, then check
#   inside.sh check    check only, against a home another container prepared
#   inside.sh refuse   the bootstrap must exit non-zero and leave $HOME alone

set -u

export DOTFILES_TARBALL=file:///src/dotfiles.tar.gz
export DOTFILES_REPO=
export BOOTSTRAP_SKIP='claude trash-cli'

# The bootstrap arrives on a pipe, as it does from a URL, so a step that reads
# stdin would eat the rest of the script and show up here.
bootstrap() { cat /src/bootstrap.sh | sh; }

# Paths and link targets under $HOME, leaving out what changes on every use.
listing() {
  find "$HOME" \
    \( -path "$HOME/.cache" -o -path "$HOME/.local/state" -o -path "$HOME/.local/share/nvim" -o -name '.zcompdump*' -o -name '.histfile' \) -prune \
    -o -printf '%P -> %l\n' | sort
}

case ${1:-full} in
  refuse)
    ls -A "$HOME" > /tmp/before
    bootstrap
    status=$?
    ls -A "$HOME" > /tmp/after
    [ "$status" -ne 0 ] || { echo "FAIL: the bootstrap exited 0"; exit 1; }
    cmp -s /tmp/before /tmp/after || { echo "FAIL: \$HOME changed"; diff /tmp/before /tmp/after; exit 1; }
    echo "PASS: refused with status $status and left \$HOME alone"
    ;;
  check)
    sh /src/check.sh
    ;;
  full)
    echo "######## first run"
    bootstrap || { echo "FAIL: first run exited $?"; exit 1; }
    listing > /tmp/after-first
    echo "######## second run"
    bootstrap || { echo "FAIL: second run exited $?"; exit 1; }
    listing > /tmp/after-second
    if ! cmp -s /tmp/after-first /tmp/after-second; then
      echo "FAIL: the second run changed \$HOME"
      diff /tmp/after-first /tmp/after-second | head -40
      exit 1
    fi
    echo "PASS: the second run changed nothing"
    echo "######## checks"
    sh /src/check.sh
    ;;
esac
