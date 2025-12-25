-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup {
  spec = {
    { import = 'plugins.core' },
    { import = 'plugins.extra.guess-indent' },
    { import = 'plugins.extra.which-key' },
    { import = 'plugins.extra.leetcode' },
    -- { import = 'kickstart.plugins.debug'},
    -- { import = 'kickstart.plugins.indent_line'},
    -- { import = 'kickstart.plugins.lint'},
    -- { import = 'kickstart.plugins.autopairs'},
    -- { import = 'kickstart.plugins.neo-tree'},
    -- { import = 'kickstart.plugins.gitsigns'}, -- adds gitsigns recommend keymaps
  },
  rocks = { enabled = false },
  defaults = { lazy = true },
}
