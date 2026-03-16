return {
  'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
  keys = {
    {
      '<leader>tl',
      function()
        require('lsp_lines').toggle()
      end,
      desc = 'Toggle lsp_lines',
    },
  },
  event = { 'BufReadPre' },
}
