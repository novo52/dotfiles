-- The terminal's 16 colours in hex, for the contexts that cannot inherit them.
--
-- config/colors.lua keeps cterm highlights authoritative with termguicolors off,
-- so in a terminal Neovim draws with whatever palette the terminal has. A gui
-- frontend has no palette to inherit; mirror_terminal_colors() gives it the same
-- look by rewriting every highlight's gui colours from its cterm indices.
--
-- The values are those of term/palette.tsv, the source of truth. `term/generate.sh
-- lua-table` prints this table from that file.
local M = {}

local ansi = {
  '#2b2b2b', -- 0 black
  '#cc0000', -- 1 red
  '#4e9a06', -- 2 green
  '#c4a000', -- 3 yellow
  '#3465a4', -- 4 blue
  '#75507b', -- 5 magenta
  '#06989a', -- 6 cyan
  '#d3d7cf', -- 7 white
  '#555753', -- 8 bright black
  '#ef2929', -- 9 bright red
  '#8ae234', -- 10 bright green
  '#fce94f', -- 11 bright yellow
  '#729fcf', -- 12 bright blue
  '#ad7fa8', -- 13 bright magenta
  '#34e2e2', -- 14 bright cyan
  '#eeeeec', -- 15 bright white
}

M.ansi = ansi
M.fg = '#ffffff'
M.bg = '#2b2b2b'

local cube = { 0, 95, 135, 175, 215, 255 }

-- Hex for a 256-colour index: the terminal's own palette below 16, then the standard
-- 6x6x6 cube and 24-step greyscale ramp, which every terminal renders identically.
function M.hex(i)
  if i < 16 then
    return ansi[i + 1]
  elseif i < 232 then
    local n = i - 16
    return string.format('#%02x%02x%02x', cube[math.floor(n / 36) + 1], cube[math.floor(n % 36 / 6) + 1], cube[n % 6 + 1])
  else
    local v = 8 + (i - 232) * 10
    return string.format('#%02x%02x%02x', v, v, v)
  end
end

-- Rewrite every highlight group's gui colours from its cterm indices. The cterm side is
-- authoritative: gui colours the colorscheme set on its own are dropped, since they
-- would otherwise win over the cterm values this config actually specifies.
--
-- This turns termguicolors on, so it belongs only in a gui frontend.
function M.mirror_terminal_colors()
  vim.o.termguicolors = true

  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if not hl.link and name ~= 'Normal' then
      hl.fg = hl.ctermfg and M.hex(hl.ctermfg) or nil
      hl.bg = hl.ctermbg and M.hex(hl.ctermbg) or nil
      hl.sp = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end

  -- The `vim` colorscheme leaves Normal empty in cterm mode and inherits the terminal's
  -- foreground and background. A gui frontend has neither, so state them.
  vim.api.nvim_set_hl(0, 'Normal', { fg = M.fg, bg = M.bg })
end

return M
