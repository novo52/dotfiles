return { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    -- delay between pressing a key and opening which-key (milliseconds)
    -- this setting is independent of vim.o.timeoutlen
    delay = 0,
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = {},
    },

    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>l', group = '[L]eetcode' },
    },
  },
}
