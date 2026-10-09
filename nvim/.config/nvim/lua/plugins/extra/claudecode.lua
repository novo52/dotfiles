-- Claude Code IDE integration: runs a WebSocket MCP server that the `claude`
-- CLI connects to, giving it the current selection, buffer diffs, and file adds.
return {
  'coder/claudecode.nvim',
  -- Only needed by the snacks terminal provider, which `provider = 'none'` disables.
  -- dependencies = { 'folke/snacks.nvim' },
  opts = {
    -- Claude runs in tmux, not in a Neovim split. Without this, a successful
    -- send calls terminal.ensure_visible() and spawns a second, unrelated CLI.
    terminal = { provider = 'none' },
  },
  -- The WebSocket server starts inside setup(), and a `claude` running outside
  -- Neovim can only discover it via the lockfile that start writes. Loading on
  -- cmd/keys alone would mean no server until a command is invoked here first.
  event = 'VeryLazy',
  cmd = {
    -- Terminal-only, and so no-ops under `provider = 'none'`. SelectModel belongs
    -- here too: it delegates to `ClaudeCode --model <choice>`.
    -- 'ClaudeCode',
    -- 'ClaudeCodeFocus',
    -- 'ClaudeCodeSelectModel',
    -- 'ClaudeCodeOpen',
    -- 'ClaudeCodeClose',
    'ClaudeCodeAdd',
    'ClaudeCodeSend',
    'ClaudeCodeTreeAdd',
    'ClaudeCodeStatus',
    'ClaudeCodeStart',
    'ClaudeCodeStop',
    'ClaudeCodeDiffAccept',
    'ClaudeCodeDiffDeny',
    'ClaudeCodeCloseAllDiffs',
  },
  keys = {
    { '<leader>a', nil, desc = 'AI/Claude Code' },
    -- Inert under `provider = 'none'`; they only manage an in-Neovim terminal.
    -- { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
    -- { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    -- { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
    -- { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    -- { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
    { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send to Claude' },
    { '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>', desc = 'Add file', ft = { 'neo-tree', 'oil', 'netrw' } },
    { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
    { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
  },
}
