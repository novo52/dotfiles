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
    -- { import = 'plugins.extra.leetcode' },
    -- { import = 'plugins.extra.unity' },
    -- { import = 'plugins.extra.debug'},
    -- { import = 'plugins.extra.indent_line'},
    -- { import = 'plugins.extra.lint'},
    -- { import = 'plugins.extra.autopairs'},
    { import = 'plugins.extra.neo-tree' },
    { import = 'plugins.extra.lsp_lines' },
    { import = 'plugins.extra.fold' },
    -- { import = 'plugins.extra.gitsigns'}, -- adds gitsigns recommend keymaps
  },
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
  change_detection = {
    enabled = false,
    notify = false,
  },
}
