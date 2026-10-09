return {
  'lervag/vimtex',
  lazy = false, -- we don't want to lazy load VimTeX
  tag = 'v2.18', -- last release supporting nvim 0.12.2; master requires 0.12.4
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = 'zathura'
  end,
}
