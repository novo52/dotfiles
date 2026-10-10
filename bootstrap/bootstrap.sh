#!/bin/sh
# Sets up this configuration on a machine, starting from nothing but a POSIX
# shell and curl or wget:
#
#   curl -fsSL https://raw.githubusercontent.com/novo52/dotfiles/main/bootstrap/bootstrap.sh | sh
#
# Everything lands in $HOME. Root is used only to install distro packages, and
# only when sudo works; without it the same tools come from conda-forge.
# Running it again brings the machine up to date. README.md beside this file
# describes where each tool comes from.
#
# Installed as `dots`:
#   dots [install] [--minimal] [--no-sudo]
#   dots private [package ...]   clone the private overlay and stow packages from it
#   dots verify                  check the installed result, change nothing
#
# Environment:
#   DOTFILES_DIR      checkout location                  (~/dotfiles)
#   DOTFILES_TARBALL  where a missing checkout comes from
#   DOTFILES_REPO     clone URL; empty leaves a tarball checkout as plain files
#   BOOTSTRAP_SKIP    space-separated steps to leave out, from:
#                     packages plugins fonts claude trash-cli

set -u

DOTFILES_DIR=${DOTFILES_DIR:-$HOME/dotfiles}
DOTFILES_TARBALL=${DOTFILES_TARBALL:-https://github.com/novo52/dotfiles/archive/refs/heads/main.tar.gz}
DOTFILES_REPO=${DOTFILES_REPO-https://github.com/novo52/dotfiles.git}
PRIVATE_REPO=${PRIVATE_REPO:-novo52/dotfiles-private}
PRIVATE_DIR=${PRIVATE_DIR:-$HOME/dotfiles-private}
BOOTSTRAP_SKIP=${BOOTSTRAP_SKIP:-}

PUBLIC_PACKAGES='zsh bash git tmux nvim'
TOOL_BINS='tree-sitter rg fd fzf'
BASE_BINS='zsh git stow gh'

BIN=$HOME/.local/bin
BACKUP=$HOME/.local/share/dotfiles-backups/$(date +%Y-%m-%d)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap.XXXXXX") || exit 1
LOG=$TMP/log
REPORT=$TMP/report
: > "$LOG"
: > "$REPORT"
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

PATH=$BIN:$PATH
export PATH

# ---------------------------------------------------------------- helpers

step() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }

# result <ok|skip|fail> <name> <detail>
result() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$REPORT"
  printf '    [%s] %s: %s\n' "$1" "$2" "$3"
}

die() {
  printf '\nbootstrap: %s\n' "$*" >&2
  exit 2
}

have() { command -v "$1" > /dev/null 2>&1; }

skipped() {
  case " $BOOTSTRAP_SKIP " in *" $1 "*) return 0 ;; esac
  return 1
}

# Every command runs with stdin closed: when this script arrives on a pipe, a
# child that reads stdin would swallow the rest of it.
quiet() { "$@" >> "$LOG" 2>&1 < /dev/null; }

show_log_tail() { tail -n 15 "$LOG" | sed 's/^/      | /'; }

fetch() { # fetch <url> <destination>
  if have curl; then
    quiet curl -fsSL --retry 3 -o "$2" "$1"
  else
    quiet wget -q -O "$2" "$1"
  fi
}

# tool_field <name> <column>, reading tools.tsv
tool_field() {
  awk -F '\t' -v n="$1" -v c="$2" '$1 == n { print $c; exit }' "$DOTFILES_DIR/bootstrap/tools.tsv"
}

# The path a command resolves to when ~/.local/bin is left out of PATH.
system_path_of() {
  (
    PATH=$(printf '%s' "$PATH" | tr ':' '\n' | grep -v -x "$BIN" | tr '\n' ':')
    command -v "$1"
  ) 2> /dev/null
}

# ---------------------------------------------------------------- detection

detect() {
  ARCH=$(uname -m)
  OS=$(uname -s)
  [ "$OS" = Linux ] || die "this bootstrap supports Linux; found $OS."

  GLIBC=$(getconf GNU_LIBC_VERSION 2> /dev/null | awk '{ print $2 }')
  if [ -z "$GLIBC" ]; then
    die "no glibc found (a musl system such as Alpine?). The pinned binaries are glibc builds, so nothing was installed."
  fi
  GLIBC_MINOR=${GLIBC#2.}
  GLIBC_MINOR=${GLIBC_MINOR%%.*}

  case $ARCH in
    x86_64) CONDA_PLATFORM=linux-64 ;;
    aarch64) CONDA_PLATFORM=linux-aarch64 ;;
    *) CONDA_PLATFORM=unknown ;;
  esac

  have curl || have wget || die "need curl or wget to download anything."
  have tar && have gzip || die "need tar and gzip."

  IS_WSL=no
  grep -qi microsoft /proc/version 2> /dev/null && IS_WSL=yes

  HOME_FS=$(stat -f -c %T "$HOME" 2> /dev/null || echo unknown)
  case $HOME_FS in
    nfs* | cifs | smb* | lustre | gpfs | afs | ceph | fuse.sshfs) SHARED_HOME=yes ;;
    *) SHARED_HOME=no ;;
  esac

  PKG=none
  for m in apt-get dnf pacman zypper; do
    if have $m; then PKG=$m; break; fi
  done

  SUDO=no
  if [ "$NO_SUDO" = no ] && [ "$PKG" != none ] && have sudo; then
    if sudo -n true 2> /dev/null; then
      SUDO=yes
    elif [ -t 1 ] && [ -r /dev/tty ] && sudo -v < /dev/tty; then
      SUDO=yes
    fi
  fi
  [ "$(id -u)" = 0 ] && die "run this as the user whose home is being set up, not as root."

  PREFIX=$HOME/.local/opt/$ARCH-glibc$GLIBC
  MAMBA=$PREFIX/micromamba
  MAMBA_ROOT_PREFIX=$PREFIX/mamba
  export MAMBA_ROOT_PREFIX
}

# ---------------------------------------------------------------- steps

get_checkout() {
  step "Configuration checkout"
  if [ -r "$DOTFILES_DIR/bootstrap/tools.tsv" ]; then
    if [ -d "$DOTFILES_DIR/.git" ] && have git; then
      if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain 2>> "$LOG")" ]; then
        result skip checkout "$DOTFILES_DIR has local changes; left as it is"
      elif quiet git -C "$DOTFILES_DIR" pull --ff-only; then
        result ok checkout "$DOTFILES_DIR at $(git -C "$DOTFILES_DIR" rev-parse --short HEAD)"
      else
        result skip checkout "$DOTFILES_DIR could not be fast-forwarded; left as it is"
      fi
    else
      result ok checkout "$DOTFILES_DIR already present"
    fi
    return
  fi
  [ -e "$DOTFILES_DIR" ] && die "$DOTFILES_DIR exists and is not this configuration."

  if [ -n "$DOTFILES_REPO" ] && have git; then
    quiet git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || { show_log_tail; die "could not clone $DOTFILES_REPO."; }
    result ok checkout "cloned to $DOTFILES_DIR"
    return
  fi

  fetch "$DOTFILES_TARBALL" "$TMP/dotfiles.tar.gz" || { show_log_tail; die "could not download $DOTFILES_TARBALL."; }
  mkdir -p "$DOTFILES_DIR"
  quiet tar -xzf "$TMP/dotfiles.tar.gz" -C "$DOTFILES_DIR" --strip-components=1 || die "could not unpack the configuration tarball."
  [ -r "$DOTFILES_DIR/bootstrap/tools.tsv" ] || die "the tarball at $DOTFILES_TARBALL is not this configuration."
  result ok checkout "unpacked to $DOTFILES_DIR"
}

# A tarball checkout has no history, so it cannot be updated. Once git exists,
# attach the repository to the files already in place.
attach_repository() {
  [ -n "$DOTFILES_REPO" ] || return 0
  [ -d "$DOTFILES_DIR/.git" ] && return 0
  have git || return 0
  if quiet git clone --no-checkout "$DOTFILES_REPO" "$TMP/clone" &&
    mv "$TMP/clone/.git" "$DOTFILES_DIR/.git" &&
    quiet git -C "$DOTFILES_DIR" reset; then
    result ok repository "$DOTFILES_DIR is a clone of $DOTFILES_REPO"
  else
    result skip repository "could not attach $DOTFILES_REPO; the checkout stays as plain files"
  fi
}

system_packages() {
  step "System packages"
  if skipped packages; then
    result skip packages "left out by BOOTSTRAP_SKIP"
    return
  fi
  if [ "$SUDO" = no ]; then
    result skip packages "no sudo; missing tools come from conda-forge"
    return
  fi
  case $PKG in
    apt-get) names='zsh git stow gh xz-utils unzip gcc libc6-dev fontconfig' ;;
    dnf) names='zsh git stow gh xz unzip gcc fontconfig' ;;
    pacman) names='zsh git stow github-cli xz unzip gcc fontconfig' ;;
    zypper) names='zsh git stow gh xz unzip gcc fontconfig' ;;
  esac
  [ "$PKG" = apt-get ] && quiet sudo -n apt-get update
  installed='' failed=''
  # One at a time, so a name the distro lacks does not sink the rest.
  for p in $names; do
    case $PKG in
      apt-get) quiet sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$p" ;;
      dnf) quiet sudo -n dnf install -y "$p" ;;
      pacman) quiet sudo -n pacman -S --noconfirm --needed "$p" ;;
      zypper) quiet sudo -n zypper --non-interactive install "$p" ;;
    esac && installed="$installed $p" || failed="$failed $p"
  done
  result ok packages "$PKG:$installed"
  [ -z "$failed" ] || result skip packages "not available from $PKG:$failed"
}

install_micromamba() {
  step "micromamba"
  want=$(tool_field micromamba 3)
  if [ -x "$MAMBA" ] && [ "$("$MAMBA" --version 2> /dev/null)" = "$want" ]; then
    result ok micromamba "$want already present"
    return 0
  fi
  mkdir -p "$PREFIX"
  if fetch "$(tool_field micromamba 5)" "$TMP/micromamba" && chmod +x "$TMP/micromamba" &&
    [ "$("$TMP/micromamba" --version 2> /dev/null)" = "$want" ]; then
    mv "$TMP/micromamba" "$MAMBA"
    result ok micromamba "$want"
  else
    show_log_tail
    result fail micromamba "could not install $want"
    return 1
  fi
}

# conda_env <directory name> <lockfile>
conda_env() {
  env_dir=$PREFIX/$1
  lock=$DOTFILES_DIR/bootstrap/$2
  stamp=$(cksum < "$lock")
  if [ -r "$env_dir/.lock-cksum" ] && [ "$(cat "$env_dir/.lock-cksum")" = "$stamp" ]; then
    result ok "conda:$1" "matches $2"
    return 0
  fi
  rm -rf "$env_dir"
  if quiet "$MAMBA" create -y -p "$env_dir" -f "$lock"; then
    printf '%s\n' "$stamp" > "$env_dir/.lock-cksum"
    quiet "$MAMBA" clean -a -y
    result ok "conda:$1" "created from $2"
  else
    show_log_tail
    result fail "conda:$1" "could not create the environment from $2"
    return 1
  fi
}

conda_tools() {
  step "Tools from conda-forge"
  if [ ! -r "$DOTFILES_DIR/bootstrap/conda-$CONDA_PLATFORM.lock" ]; then
    result fail conda "no lockfile for $ARCH ($CONDA_PLATFORM)"
    return
  fi
  [ -x "$MAMBA" ] || { result fail conda "micromamba is missing"; return; }

  if conda_env env "conda-$CONDA_PLATFORM.lock"; then
    for b in $TOOL_BINS; do ln -sfn "$PREFIX/env/bin/$b" "$BIN/$b"; done
  fi

  # zsh, git, stow and gh are large, so their environment is created only when
  # the system lacks at least one of them, and only the missing ones are linked.
  missing=''
  for b in $BASE_BINS; do
    [ -n "$(system_path_of "$b")" ] || missing="$missing $b"
  done
  if [ -z "$missing" ]; then
    result ok conda:base "not needed; the system provides: $BASE_BINS"
    return
  fi
  if conda_env base "conda-$CONDA_PLATFORM-base.lock"; then
    for b in $missing; do ln -sfn "$PREFIX/base/bin/$b" "$BIN/$b"; done
    info "linked from conda-forge:$missing"
  fi
}

install_nvim() {
  step "Neovim"
  want=$(tool_field nvim 3)
  floor=$(tool_field nvim 4)
  if [ "$ARCH" != x86_64 ]; then
    result fail nvim "the pinned release is an x86_64 build; this machine is $ARCH"
    return
  fi
  if [ "$GLIBC_MINOR" -lt "${floor#2.}" ]; then
    result fail nvim "$want needs glibc $floor; this machine has $GLIBC"
    return
  fi
  dir=$PREFIX/nvim-linux-x86_64
  if [ "$("$dir/bin/nvim" --version 2> /dev/null | head -n 1)" = "NVIM v$want" ]; then
    ln -sfn "$dir/bin/nvim" "$BIN/nvim"
    result ok nvim "$want already present"
    return
  fi
  if fetch "$(tool_field nvim 5)" "$TMP/nvim.tar.gz" && rm -rf "$dir" && quiet tar -xzf "$TMP/nvim.tar.gz" -C "$PREFIX"; then
    # A release tag is no guarantee of the version inside the tarball.
    got=$("$dir/bin/nvim" --version 2> /dev/null | head -n 1)
    if [ "$got" = "NVIM v$want" ]; then
      ln -sfn "$dir/bin/nvim" "$BIN/nvim"
      result ok nvim "$want"
    else
      result fail nvim "the tarball contains '$got', expected v$want"
    fi
  else
    show_log_tail
    result fail nvim "could not download or unpack $want"
  fi
}

FONT_FAMILY='JetBrainsMonoNL Nerd Font Mono'

install_fonts() {
  step "Fonts"
  WANT_FONT_PACKAGE=no
  if skipped fonts; then
    result skip fonts "left out by BOOTSTRAP_SKIP"
    return
  fi
  if [ "$IS_WSL" = yes ]; then
    result skip fonts "under WSL the Windows terminal renders text; install the font on Windows"
    return
  fi
  if ! have fc-cache || ! have fc-list; then
    result skip fonts "no fontconfig, so nothing here draws text"
    return
  fi
  WANT_FONT_PACKAGE=yes
  if fc-list 2> /dev/null | grep -q "$FONT_FAMILY"; then
    result ok fonts "$FONT_FAMILY already present"
    return
  fi
  if ! have xz; then
    result skip fonts "xz is needed to unpack the font archive"
    return
  fi
  dest=$HOME/.local/share/fonts/JetBrainsMonoNL
  mkdir -p "$dest" "$TMP/font"
  if fetch "$(tool_field nerd-font 5)" "$TMP/font.tar.xz" &&
    quiet tar -xJf "$TMP/font.tar.xz" -C "$TMP/font" &&
    cp "$TMP"/font/*NLNerdFontMono-*.ttf "$dest"/ && quiet fc-cache -f; then
    result ok fonts "$FONT_FAMILY $(tool_field nerd-font 3) in $dest"
  else
    show_log_tail
    result fail fonts "could not install $FONT_FAMILY"
  fi
}

# Stow refuses to replace a file it does not own. Anything in the way of a
# package is moved to the backup directory, keeping its relative path.
# clear_the_way <package directory>
clear_the_way() {
  (cd "$1" && find . \( -type f -o -type l \) | sed 's|^\./||') > "$TMP/files"
  while IFS= read -r rel; do
    target=$HOME/$rel
    [ -e "$target" ] || [ -L "$target" ] || continue
    [ "$(readlink -f "$target")" = "$(readlink -f "$1/$rel")" ] && continue
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$target" "$BACKUP/$rel"
    info "moved ~/$rel to $BACKUP/"
  done < "$TMP/files"
}

# stow_packages <repository> <package ...>
stow_packages() {
  repo=$1
  shift
  for p in "$@"; do
    if [ ! -d "$repo/$p" ]; then
      result fail "stow:$p" "no such package in $repo"
      continue
    fi
    clear_the_way "$repo/$p"
    if quiet stow -d "$repo" -t "$HOME" --no-folding -R "$p"; then
      result ok "stow:$p" "linked"
    else
      show_log_tail
      result fail "stow:$p" "stow reported a conflict"
    fi
  done
}

link_configuration() {
  step "Configuration"
  if ! have stow; then
    result fail stow "stow is not available"
    return
  fi
  packages=$PUBLIC_PACKAGES
  [ "$WANT_FONT_PACKAGE" = yes ] && packages="$packages font"
  # shellcheck disable=SC2086
  stow_packages "$DOTFILES_DIR" $packages
}

install_oh_my_zsh() {
  step "oh-my-zsh"
  if ! have git; then
    result fail oh-my-zsh "git is not available"
    return
  fi
  if [ -d "$HOME/.oh-my-zsh" ]; then
    result ok oh-my-zsh "already present"
  elif quiet git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; then
    result ok oh-my-zsh "installed"
  else
    show_log_tail
    result fail oh-my-zsh "could not clone"
    return
  fi
  vi=$HOME/.oh-my-zsh/custom/plugins/zsh-vi-mode
  if [ -d "$vi" ]; then
    result ok zsh-vi-mode "already present"
  elif quiet git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git "$vi"; then
    result ok zsh-vi-mode "installed"
  else
    result fail zsh-vi-mode "could not clone"
  fi
}

nvim_plugins() {
  step "Neovim plugins"
  if skipped plugins; then
    result skip plugins "left out"
    return
  fi
  if ! have nvim || ! have git; then
    result fail plugins "needs nvim and git"
    return
  fi
  quiet nvim --headless '+Lazy! restore' +qa
  out=$(nvim --headless "+luafile $DOTFILES_DIR/bootstrap/nvim-provision.lua" +qa 2>> "$LOG" < /dev/null | tr -d '\r' | grep '^provisioned:')
  if [ -n "$out" ]; then
    result ok plugins "${out#provisioned: }"
    servers=${out##*, }
    if [ "${servers%% of *}" != "$(printf '%s' "${servers#* of }" | cut -d' ' -f1)" ]; then
      result skip language-servers "mason installed only $servers; it needs unzip, tar and gzip"
    fi
  else
    show_log_tail
    result fail plugins "nvim did not finish provisioning"
  fi
  if ! have cc && ! have gcc && ! have clang; then
    result skip parsers "no C compiler, so treesitter parsers cannot be built here"
  fi
}

extras() {
  step "Extras"
  if skipped trash-cli; then
    result skip trash-cli "left out"
  elif have trash; then
    result ok trash-cli "already present"
  elif have python3 && quiet python3 -m pip install --user "$(tool_field trash-cli 5)"; then
    result ok trash-cli "installed with pip"
  else
    result skip trash-cli "pip could not install it into the user site"
  fi

  if skipped claude; then
    result skip claude "left out"
  elif have claude; then
    result ok claude "already present"
  elif have bash && fetch "$(tool_field claude 5)" "$TMP/claude-install.sh" && quiet bash "$TMP/claude-install.sh"; then
    result ok claude "installed"
  else
    result skip claude "the installer did not complete"
  fi
}

link_dots() {
  ln -sfn "$DOTFILES_DIR/bootstrap/bootstrap.sh" "$BIN/dots"
}

verify() {
  step "Verification"
  for f in "$HOME/.zshenv" "$HOME/.config/zsh/.zshrc" "$HOME/.config/zsh/.zsh_aliases"; do
    if [ ! -r "$f" ]; then
      result fail "check:$(basename "$f")" "missing"
    elif have zsh && ! quiet zsh -n "$f"; then
      result fail "check:$(basename "$f")" "zsh reports a syntax error"
    fi
  done

  if have zsh; then
    out=$(zsh -ic 'print -r -- "zsh $ZSH_VERSION"' 2>&1 < /dev/null)
    if [ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ]; then
      result ok check:zsh "$out starts cleanly"
    else
      printf '%s\n' "$out" | sed 's/^/      | /'
      result fail check:zsh "an interactive shell printed messages on startup"
    fi
  else
    result fail check:zsh "zsh is not on PATH"
  fi

  for b in nvim git stow $TOOL_BINS; do
    if have "$b"; then
      result ok "check:$b" "$("$b" --version 2> /dev/null | head -n 1)"
    else
      result fail "check:$b" "not on PATH"
    fi
  done

  if have nvim && ! skipped plugins; then
    out=$(nvim --headless '+sleep 2' +qa 2>&1 < /dev/null | tr -d '\r')
    case $out in
      '') result ok check:nvim-start "starts without messages" ;;
      *'needs'*'C compiler'*) result skip check:nvim-start "warns that parsers cannot be built" ;;
      *)
        printf '%s\n' "$out" | sed 's/^/      | /'
        result fail check:nvim-start "printed messages on startup"
        ;;
    esac
  fi

  if [ "${WANT_FONT_PACKAGE:-no}" = yes ]; then
    got=$(fc-match -f '%{family}' monospace 2> /dev/null)
    case $got in
      *JetBrainsMonoNL*) result ok check:font "monospace is $got" ;;
      *) result fail check:font "monospace resolves to '$got'" ;;
    esac
  fi
}

report() {
  ok=$(grep -c '^ok' "$REPORT")
  skip=$(grep -c '^skip' "$REPORT")
  fail=$(grep -c '^fail' "$REPORT")
  printf '\n==> Summary: %s ok, %s skipped, %s failed\n' "$ok" "$skip" "$fail"
  if [ "$skip" -gt 0 ]; then
    printf '    Skipped:\n'
    awk -F '\t' '$1 == "skip" { printf "      %s: %s\n", $2, $3 }' "$REPORT"
  fi
  if [ "$fail" -gt 0 ]; then
    printf '    Failed:\n'
    awk -F '\t' '$1 == "fail" { printf "      %s: %s\n", $2, $3 }' "$REPORT"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------- commands

cmd_install() {
  detect
  step "This machine"
  info "$ARCH, glibc $GLIBC, packages via $PKG, sudo: $SUDO, WSL: $IS_WSL"
  info "home on $HOME_FS (shared: $SHARED_HOME); tools go to $PREFIX"
  [ "$CONDA_PLATFORM" = unknown ] && die "no pinned tools exist for $ARCH."

  mkdir -p "$BIN" "$PREFIX"
  get_checkout
  system_packages
  install_micromamba && conda_tools
  attach_repository
  install_nvim
  install_fonts
  link_configuration
  install_oh_my_zsh
  nvim_plugins
  extras
  link_dots
  verify
  if report; then
    printf '\nDone. Start a new login shell, or run: exec zsh -l\n'
    printf 'For this machine'\''s own settings: dots private <package>\n'
  else
    exit 1
  fi
}

cmd_verify() {
  detect
  WANT_FONT_PACKAGE=no
  [ -L "$HOME/.config/fontconfig/fonts.conf" ] && have fc-match && WANT_FONT_PACKAGE=yes
  verify
  report || exit 1
}

cmd_private() {
  detect
  step "Private overlay"
  have git && have stow || die "git and stow are needed; run 'dots' first."
  if [ ! -d "$PRIVATE_DIR/.git" ]; then
    if have gh && gh auth status > /dev/null 2>&1; then
      quiet gh repo clone "$PRIVATE_REPO" "$PRIVATE_DIR" || { show_log_tail; die "could not clone $PRIVATE_REPO."; }
    else
      die "sign in to GitHub first with 'gh auth login', then run this again."
    fi
    result ok private "cloned to $PRIVATE_DIR"
  else
    quiet git -C "$PRIVATE_DIR" pull --ff-only
    result ok private "$PRIVATE_DIR at $(git -C "$PRIVATE_DIR" rev-parse --short HEAD)"
  fi
  if [ $# -eq 0 ]; then
    printf '\nPackages available; name the ones this machine should have:\n'
    (cd "$PRIVATE_DIR" && for d in */; do [ "$d" = docs/ ] || printf '  %s\n' "${d%/}"; done)
    return
  fi
  stow_packages "$PRIVATE_DIR" "$@"
  report || exit 1
}

NO_SUDO=no
COMMAND=install
case ${1:-} in
  install | private | verify)
    COMMAND=$1
    shift
    ;;
  -h | --help | help)
    sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

if [ "$COMMAND" = private ]; then
  cmd_private "$@"
  exit 0
fi

while [ $# -gt 0 ]; do
  case $1 in
    --minimal) BOOTSTRAP_SKIP="$BOOTSTRAP_SKIP plugins claude trash-cli" ;;
    --no-sudo) NO_SUDO=yes ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

case $COMMAND in
  install) cmd_install ;;
  verify) cmd_verify ;;
esac
