#!/bin/sh
# Runs the bootstrap from nothing in disposable Docker containers and checks
# the result. The working tree is what gets tested, committed or not.
#
#   bootstrap/test/run.sh [environment ...]
#
# With no arguments, every environment runs:
#
#   ubuntu20-nosudo  glibc 2.31, no root, no git/zsh/stow/compiler
#   ubuntu24-sudo    glibc 2.39, passwordless sudo, apt
#   fedora-sudo      current glibc, passwordless sudo, dnf
#   alpine           musl; the bootstrap must refuse and leave $HOME alone
#   shared-home      ubuntu20-nosudo and ubuntu24-sudo in turn on one home
#
# Each container starts with the distro's skeleton files in a fresh home, runs
# the bootstrap twice from a pipe, and then runs check.sh. Logs are kept in
# $TEST_LOGS, /tmp/dotfiles-bootstrap-test by default.

set -u

REPO=$(cd "$(dirname "$0")/../.." && pwd)
LOGS=${TEST_LOGS:-/tmp/dotfiles-bootstrap-test}
SRC=$LOGS/src
ALL='ubuntu20-nosudo ubuntu24-sudo fedora-sudo alpine shared-home'

mkdir -p "$SRC"
(cd "$REPO" && git ls-files -co --exclude-standard -z | tar --null -T - --transform 's|^|dotfiles-main/|' -czf "$SRC/dotfiles.tar.gz") || exit 1
cp "$REPO/bootstrap/bootstrap.sh" "$REPO/bootstrap/test/check.sh" "$REPO/bootstrap/test/inside.sh" "$SRC/"

dockerfile() {
  case $1 in
    ubuntu20-nosudo)
      cat << 'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1234 -s /bin/bash tester
EOF
      ;;
    ubuntu24-sudo)
      cat << 'EOF'
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates sudo && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1234 -s /bin/bash tester && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
EOF
      ;;
    fedora-sudo)
      cat << 'EOF'
FROM fedora:latest
RUN dnf install -y sudo tar gzip findutils util-linux-script || dnf install -y sudo tar gzip findutils util-linux
RUN useradd -m -u 1234 -s /bin/bash tester && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
EOF
      ;;
    alpine)
      cat << 'EOF'
FROM alpine:latest
RUN apk add --no-cache curl && adduser -D -u 1234 tester
EOF
      ;;
  esac
}

build() {
  dockerfile "$1" | docker build -q -t "dotfiles-test-$1" - > "$LOGS/$1.build.log" 2>&1
}

# run_in <image environment> <log name> <mode> [extra docker arguments]
run_in() {
  image=$1 log=$2 mode=$3
  shift 3
  docker run --rm -u tester -w /home/tester -v "$SRC:/src:ro" "$@" \
    "dotfiles-test-$image" sh /src/inside.sh "$mode" > "$LOGS/$log.log" 2>&1
}

verdict() { # verdict <environment> <status>
  if [ "$2" -eq 0 ]; then
    printf 'PASS  %s\n' "$1"
  else
    printf 'FAIL  %s   (see %s)\n' "$1" "$LOGS/$1*.log"
    FAILED=1
  fi
}

FAILED=0
for env in ${*:-$ALL}; do
  case $env in
    ubuntu20-nosudo | ubuntu24-sudo | fedora-sudo)
      build "$env" && run_in "$env" "$env" full
      verdict "$env" $?
      ;;
    alpine)
      build alpine && run_in alpine alpine refuse
      verdict alpine $?
      ;;
    shared-home)
      vol=dotfiles-test-home-$$
      docker volume create "$vol" > /dev/null
      # A fresh named volume is seeded from the image's /home/tester, skeleton
      # files included, the first time it is mounted.
      build ubuntu20-nosudo && build ubuntu24-sudo &&
        run_in ubuntu20-nosudo shared-home.1-ubuntu20 full -v "$vol:/home/tester" &&
        run_in ubuntu24-sudo shared-home.2-ubuntu24 full -v "$vol:/home/tester" &&
        run_in ubuntu20-nosudo shared-home.3-ubuntu20-again check -v "$vol:/home/tester"
      status=$?
      docker volume rm "$vol" > /dev/null
      verdict shared-home $status
      ;;
    *)
      printf 'unknown environment: %s\n' "$env" >&2
      FAILED=1
      ;;
  esac
done
exit $FAILED
