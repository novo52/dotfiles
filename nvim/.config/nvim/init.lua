if vim.loader then
  vim.loader.enable()
end

require 'config.autocmds'
require 'config.health'
require 'config.colors'
require 'config.options'
require 'config.keybinds'
require 'config.lazy'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
