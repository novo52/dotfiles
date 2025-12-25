vim.cmd.colorscheme 'vim'
vim.o.termguicolors = false

vim.api.nvim_set_hl(0, 'LineNr', { bold = true, ctermfg = 'DarkGrey' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { bold = true, ctermfg = 'Gray' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE', ctermbg = 'NONE' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE', ctermbg = 235 })
vim.api.nvim_set_hl(0, 'Visual', { bg = 'NONE', ctermbg = 238 })

