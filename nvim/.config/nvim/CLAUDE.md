# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is the Neovim config inside a GNU-stow-style dotfiles repo (`~/dotfiles`); `~/.config/nvim` is a symlink to this directory, so edits here take effect immediately. The config started as a kickstart.nvim fork but has been split into modules (the README.md is upstream kickstart boilerplate, not documentation of this config).

## Commands

- **Format Lua:** `stylua .` (config in `.stylua.toml`: 2-space indent, single quotes, no call parentheses, 160 columns). Check only: `stylua --check .`
- **Sync plugins headlessly:** `nvim --headless "+Lazy! sync" +qa` (updates `lazy-lock.json`, which is gitignored — plugin versions are not pinned across machines)
- **Health check:** `:checkhealth` includes a custom `config` check from `lua/config/health.lua`
- There are no tests.

## Architecture

`init.lua` only requires the `lua/config/*` modules in order: `autocmds`, `health`, `keybinds`, `options`, `lazy` (plugin manager + spec), `colors`.

**Plugin loading is controlled entirely by the import list in `lua/config/lazy.lua`:**
- `{ import = 'plugins.core' }` loads every file in `lua/plugins/core/` (lsp, blink completion, git, nav/telescope, misc/mini.nvim).
- Files in `lua/plugins/extra/` are opt-in, imported individually one per line; several are present but commented out (debug, lint, autopairs, leetcode, …). A new extra plugin file does nothing until its import line is added there. Each plugin file returns a lazy.nvim spec table.

**LSP config lives in two places:**
- `lua/plugins/core/lsp.lua` — mason/mason-lspconfig setup (`ensure_installed`), diagnostics config, LspAttach keymaps, and inline `vim.lsp.config` entries for wgsl_analyzer, glslls, lua_ls, clangd, rust_analyzer.
- `lua/lsp/*.lua` — Neovim 0.11+ native runtimepath `lsp/` configs (e.g. `clangd.lua` returns a `cmd` table); these merge with the inline configs above, so per-server flags may need checking in both files.

**Colors** (`lua/config/colors.lua`): uses the `vim` colorscheme with `termguicolors = false` and cterm highlight overrides — the 16/256-color terminal-palette look is deliberate; don't "fix" it by enabling truecolor.

`bs/` contains dead/scrapped config files and is not loaded by anything.
