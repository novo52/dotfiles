return {
  'kawre/leetcode.nvim',
  event = { 'VeryLazy' },
  build = ':TSUpdate html', -- if you have `nvim-treesitter` installed
  dependencies = {
    -- include a picker of your choice, see picker section for more details
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '<leader>lr', '<cmd>Leet run<cr>', '[L]eetcode [R]un' },
  },
  config = function()
    require('which-key').add { '<leader>l', group = '[L]eetcode' }
  end,
  opts = {
    injector = {
      ['rust'] = {
        before = { '#[allow(dead_code)]', 'fn main(){}', '#[allow(dead_code)]', 'struct Solution;' },
      }, ---@type table<lc.lang, lc.inject>
    },
    hooks = {
      ---@type fun(question: lc.ui.Question)[]
      ['question_enter'] = {
        function(question)
          if question.lang ~= 'rust' then
            return
          end
          local problem_dir = vim.fn.stdpath 'data' .. '/leetcode/Cargo.toml'
          local content = [[
				  [package]
				  name = "leetcode"
				  edition = "2024"
																										 
				  [lib]
				  name = "%s"
				  path = "%s"
																										 
				  [dependencies]
				  rand = "0.8"
				  regex = "1"
				  itertools = "0.14.0"
				]]
          local file = io.open(problem_dir, 'w')
          if file then
            local formatted = (content:gsub(' +', '')):format(question.q.frontend_id, question:path())
            file:write(formatted)
            file:close()
          else
            print('Failed to open file: ' .. problem_dir)
          end
        end,
      },
    },
  },
}
