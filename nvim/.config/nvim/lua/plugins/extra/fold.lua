return {
  'kevinhwang91/nvim-ufo',
  dependencies = 'kevinhwang91/promise-async',
  event = 'BufReadPost',
  config = function(_, opts)
    local handler = function(virtText, lnum, endLnum, width, truncate, ctx)
      -- include the bottom line in folded text for additional context
      local filling = ' ⋯ '
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      table.insert(virtText, { filling, 'Folded' })
      local endVirtText = ctx.get_fold_virt_text(endLnum)
      for i, chunk in ipairs(endVirtText) do
        local chunkText = chunk[1]
        local hlGroup = chunk[2]
        if i == 1 then
          chunkText = chunkText:gsub('^%s+', '')
        end
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(virtText, { chunkText, hlGroup })
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          table.insert(virtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          -- str width returned from truncate() may less than 2nd argument, need padding
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      return virtText
    end

    require('ufo').setup {
      fold_virt_text_handler = handler,
      enable_get_fold_virt_text = true,
      provider_selector = function(bufnr, filetype, buftype)
        return { 'treesitter', 'indent' }
      end,
    }

    vim.api.nvim_set_hl(0, 'Folded', { bg = 'NONE' })

    -- Keymaps for ufo
    vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
    vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
    vim.keymap.set('n', 'zK', require('ufo').peekFoldedLinesUnderCursor, { desc = 'Peek fold' })
  end,
}
