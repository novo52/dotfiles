-- Restore cursor position when opening a file
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Return to last edit position when opening files',
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- WGSL highlighting
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'wgsl',
  callback = function()
    vim.treesitter.start()
  end,
})

-- Treesitter folding
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    local buf = vim.api.nvim_get_current_buf()

    -- Only enable if treesitter parser is available for this filetype
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if not lang then
      return
    end

    local ok = pcall(vim.treesitter.start, buf, lang)
    if not ok then
      return
    end

    -- Enable folding
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[0][0].foldmethod = 'expr'
    vim.wo[0][0].foldlevel = 99 -- Start with folds open

    -- Optionally enable indentation (experimental)
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
