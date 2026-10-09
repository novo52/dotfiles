# bootstrap

`tools.tsv` lists the binaries that live in `$HOME` rather than in a system package: what version, where to fetch it, and the oldest glibc its published artifact runs against. The repo tracks the manifest; the bytes are fetched at install time, since a repo is a poor binary distribution channel and would need one build per platform.

A tool that is not in this file reaches a new machine only if someone installs it by hand. Adding a tool to a machine and adding its row here are one change.

## glibc floors

`min_glibc` is measured, not assumed:

```sh
objdump -T <binary> | grep -o 'GLIBC_2\.[0-9]*' | sort -V | tail -1
```

The published `tree-sitter` binary requires glibc 2.39, above the 2.31 on the UofA CS lab fleet, and no release in the 0.25-0.27 range goes below 2.34. Parsers compiled by that CLI are a different matter: they reference at most `GLIBC_2.14`, so a parser built on one machine loads on any of them. `dotfiles-private/docs/facts-lab.md` records how the lab's parsers were provisioned.

## Install layout

Tarballs land in `~/.local/opt/<arch>-glibc<ver>/` and are symlinked into `~/.local/bin`, which `.zshenv` puts first on PATH. The glibc component of that path matters when a fleet's OS is upgraded underneath a shared home: binaries built against glibc 2.31 would still sit in a home now running 2.39, and keying the directory by version turns that into a miss rather than a runtime failure.

The lab fleet shares one NFS home across roughly 59 workstations, so a provisioning run serves all of them. The bootstrap checks whether a tool is already present before fetching it.
