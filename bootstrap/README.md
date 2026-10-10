# bootstrap

`bootstrap.sh` sets this configuration up on a machine that has a POSIX shell and `curl` or `wget`, and nothing else:

```sh
curl -fsSL https://raw.githubusercontent.com/novo52/dotfiles/main/bootstrap/bootstrap.sh | sh
```

It needs no credentials and no root. Where `sudo` works it installs distro packages; where it does not, the same tools come from conda-forge. It ends by checking its own result and printing what was installed, skipped and failed. Running it again updates the machine, and it installs itself as `dots`:

| | |
|---|---|
| `dots` | install or update |
| `dots --minimal` | leave out nvim plugins, Claude Code and trash-cli |
| `dots --no-sudo` | take everything from conda-forge even where sudo works |
| `dots private <package ...>` | clone the private overlay through `gh` and stow the named packages |
| `dots verify` | run the checks, change nothing |

Files already in the way of a link, such as a distro's stock `~/.bashrc`, are moved to `~/.local/share/dotfiles-backups/<date>/`.

It refuses to run on a system without glibc, and on an architecture other than x86_64.

## Testing

`test/run.sh` runs the bootstrap from nothing in disposable Docker containers — Ubuntu 20.04 without root, Ubuntu 24.04 and Fedora with sudo, Alpine as the refusal case, and two distros sharing one home — twice each, then checks the result through a login shell. It tests the working tree, committed or not.

## Where tools come from

Tools that live in `$HOME` rather than in a system package arrive in two layers.

## Layer 1 — micromamba and conda-forge

`conda-linux-64.lock` is an explicit conda lockfile: one URL and hash per package. It is reconstructed with

```sh
micromamba create -y -p ~/.local/opt/<arch>-glibc<ver>/env -f conda-linux-64.lock
```

and the chosen binaries are symlinked into `~/.local/bin`, which `.zshenv` puts first on PATH. Current contents: `tree-sitter`, `rg`, `fd`, `fzf`.

`conda-linux-64-base.lock` holds `zsh`, `git`, `stow` and `gh`, 338 MB installed. Its environment is created only on a machine whose system lacks at least one of them, and only the missing ones are linked.

conda-forge is the channel this fetches from. Two of its properties are why it is the default source here:

- **Every linux-64 package is compiled against glibc 2.17**, and declares that floor as a `__glibc` constraint the solver must satisfy. The host's glibc is an input to resolution, so a package either has a build that fits or the solve fails and says so. GitHub release binaries are built on whatever CI image is current instead: no `tree-sitter` CLI release from 0.25.0 to 0.27.1 runs on glibc older than 2.34, while the conda-forge build of the same version measures `GLIBC_2.16`.
- **Runtime libraries above libc are bundled in the prefix** — `libgcc`, `libstdc++`, OpenSSL. glibc itself is not, so name lookups still go through the host's own matched glibc and LDAP users and DNS keep working. Shipping a private glibc would break them, because glibc `dlopen`s `libnss_*.so` from the system and version-matches it.

One package name also covers linux-64, aarch64 and ppc64le, so a new machine on a different architecture needs no new rows.

**The environment is never activated in a shell.** Only the selected binaries are symlinked, for the same reason `c415` is a function: a sourced environment would shadow system tools and collide with `uv`-managed projects.

Measured on the lab fleet, after `micromamba clean -a`: 29 MB total for the prefix, micromamba's own 18 MB binary included.

## Layer 2 — `tools.tsv`

What conda-forge cannot supply: tab-separated, readable by POSIX sh with

```sh
while IFS="$(printf '\t')" read -r name class version min_glibc source
```

`min_glibc` is measured, not assumed:

```sh
objdump -T <binary> | grep -o 'GLIBC_2\.[0-9]*' | sort -V | tail -1
```

A tool in neither layer reaches a new machine only if someone installs it by hand. Adding a tool to a machine and recording it here are one change.

## Install layout

Tarballs land in `~/.local/opt/<arch>-glibc<ver>/`. The glibc component matters when a fleet's OS is upgraded underneath a shared home: binaries built against glibc 2.31 would still sit in a home now running 2.39, and keying the directory by version turns that into a miss rather than a runtime failure.

The lab fleet shares one NFS home across roughly 59 workstations, so one provisioning run serves all of them. The bootstrap checks whether a tool is present before fetching it.
