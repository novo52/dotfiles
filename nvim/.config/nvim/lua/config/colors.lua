vim.cmd.colorscheme 'vim'
vim.o.termguicolors = false

vim.api.nvim_set_hl(0, 'LineNr', { bold = true, ctermfg = 'DarkGrey' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { bold = true, ctermfg = 'Gray' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE', ctermbg = 'NONE' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE', ctermbg = 235 })
vim.api.nvim_set_hl(0, 'Visual', { bg = 'NONE', ctermbg = 238 })
vim.api.nvim_set_hl(0, '@lsp.type.builtinType.rust', { link = '@Type' })

-- Diff mode: github/difftastic-style green/red instead of the vim scheme's blue/magenta
vim.api.nvim_set_hl(0, 'DiffAdd', { ctermfg = 'NONE', ctermbg = 22 }) -- lines only in this buffer: dark green
vim.api.nvim_set_hl(0, 'DiffDelete', { ctermfg = 88, ctermbg = 52 }) -- filler for lines missing here: dark red
vim.api.nvim_set_hl(0, 'DiffChange', { ctermfg = 'NONE', ctermbg = 235 }) -- changed line: subtle grey
vim.api.nvim_set_hl(0, 'DiffText', { bold = true, ctermfg = 'NONE', ctermbg = 88 }) -- changed tokens (old side): brighter red
vim.api.nvim_set_hl(0, 'DiffTextAdd', { bold = true, ctermfg = 'NONE', ctermbg = 28 }) -- added tokens within a changed line (0.12+): brighter green
