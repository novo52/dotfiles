-- Relative line numbers
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.cursorlineopt = 'number'

-- Tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- No-brainers
vim.g.have_nerd_font = true
vim.o.mouse = 'a'
vim.o.undofile = true
vim.o.inccommand = 'split'

-- For plugins / features
vim.o.signcolumn = 'yes'
vim.o.showmode = false
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Misc
vim.o.breakindent = true -- Match line break to start of line
vim.o.ignorecase = true -- Case insensitive search,
vim.o.smartcase = true -- 		unless case is used
vim.o.updatetime = 250 -- For background tasks
vim.o.timeoutlen = 100 -- For keybinds
vim.o.confirm = true -- Offer to save on exit
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.scrolloff = 10

-- Folding
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.fillchars = {
  fold = ' ',
  foldopen = '<',
  foldclose = '>',
  foldsep = ' ',
}
