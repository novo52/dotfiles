if vim.loader then
  vim.loader.enable()
end

vim.filetype.add { extension = { wgsl = 'wgsl' } }

require 'config.autocmds'
require 'config.health'
require 'config.keybinds'
require 'config.options'
require 'config.lazy'
require 'config.colors'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
