-- Neovim inside browser text areas. Pairs with the Firenvim browser extension;
-- the build step writes the native-messaging manifest the extension talks to.

-- Firenvim's renderer reads only the rgb attributes of hl_attr_define, so the
-- cterm-only highlights in config/colors.lua render as nothing there. The colours below
-- reproduce that terminal look in hex: gnome-terminal profile b1dcc9dd's palette (Tango,
-- passed through tmux unmodified), with foreground and background from the
-- Mint-Y-Dark-Purple `vte-terminal` rule. Keep them in step with the terminal theme.
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
local terminal_fg = '#ffffff'
local terminal_bg = '#2b2b2b'

-- The host whose Rich Content Editor gets the Markdown treatment below. It reaches two
-- matchers in different syntaxes: localSettings keys are JavaScript regexes, and Firenvim
-- names each buffer after the page's host, which the autocmd matches as a Lua pattern.
local canvas_host = 'canvas.ualberta.ca'
local canvas_url_pattern = (canvas_host:gsub('%.', '\\.'))
local canvas_buffer_pattern = '^' .. (canvas_host:gsub('%.', '%%.'))

local cube = { 0, 95, 135, 175, 215, 255 }

-- Hex for a 256-colour index: the terminal's own palette below 16, then the standard
-- 6x6x6 cube and 24-step greyscale ramp, which every terminal renders identically.
local function hex(i)
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
local function mirror_terminal_colors()
  vim.o.termguicolors = true

  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if not hl.link and name ~= 'Normal' then
      hl.fg = hl.ctermfg and hex(hl.ctermfg) or nil
      hl.bg = hl.ctermbg and hex(hl.ctermbg) or nil
      hl.sp = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end

  -- The `vim` colorscheme leaves Normal empty in cterm mode and inherits the terminal's
  -- foreground and background. A gui UI has neither, so state them.
  --
  -- The page keeps its own background around the frame. Reading the text area's colour to
  -- match it is not possible: firenvim#eval_js runs window.eval in the page, which a site
  -- CSP without 'unsafe-eval' refuses. Instead a uBlock Origin filter paints the text area
  -- to match this background while a frame is open, keyed on the span Firenvim appends to
  -- the body:
  --   github.com##body:has(> span[tabindex="-1"]:empty) textarea:style(background-color: #2b2b2b !important)
  vim.api.nvim_set_hl(0, 'Normal', { fg = terminal_fg, bg = terminal_bg })
end

return {
  -- Local checkout of glacambre/firenvim, so the plugin side matches the browser extension
  -- built from the same tree (`npm ci && npm run build`, loaded from target/xpi). lazy.nvim
  -- treats a `dir` plugin as unmanaged: no fetching, no lazy-lock entry.
  dir = vim.fn.expand '~/builds/firenvim',
  -- In the browser instance Firenvim must be loaded at startup; in terminal nvim it never loads.
  lazy = not vim.g.started_by_firenvim,
  build = function()
    require('lazy').load { plugins = 'firenvim', wait = true }
    vim.fn['firenvim#install'](0)
  end,
  init = function()
    -- `:call firenvim#install(0)` fails in terminal nvim: the plugin is lazy, so its
    -- autoload file isn't on the runtimepath. Load it first, then re-write the manifest.
    vim.api.nvim_create_user_command('FirenvimInstall', function()
      require('lazy').load { plugins = 'firenvim', wait = true }
      vim.fn['firenvim#install'](0)
    end, { desc = 'Reinstall the Firenvim native-messaging manifest' })

    vim.g.firenvim_config = {
      globalSettings = { alt = 'all' },
      localSettings = {
        ['.*'] = {
          cmdline = 'neovim',
          content = 'text',
          priority = 0,
          selector = 'textarea, div[role="textbox"]',
          -- Take over as soon as a text area is focused: GitHub's editor claims
          -- <C-e> for inline code, so the manual trigger is unreliable there.
          takeover = 'always',
        },
        -- Canvas's Rich Content Editor is TinyMCE, which hides the form's textarea and puts
        -- a contenteditable <body id="tinymce"> in an iframe of its own. On Firefox TinyMCE
        -- fills that iframe with document.write, which leaves the frame reporting the page's
        -- URL, so this host pattern matches inside the editor. The editor's content is
        -- markup, so the buffer holds HTML rather than the flattened text the global
        -- setting would produce.
        [canvas_url_pattern] = {
          selector = 'textarea, div[role="textbox"], body#tinymce',
          content = 'html',
          priority = 1,
        },
      },
    }
  end,
  config = function()
    -- VimEnter, because config/colors.lua is required after config/lazy.lua and would
    -- otherwise switch termguicolors back off after this ran.
    vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
      group = vim.api.nvim_create_augroup('firenvim-colors', { clear = true }),
      callback = mirror_terminal_colors,
    })

    vim.o.laststatus = 0
    vim.o.wrap = true
    vim.o.linebreak = true

    -- Every auto-write would otherwise print "<file> written" and force a cmdline
    -- redraw, which reads as the frame flashing. 'W' drops the message, cmdheight=0
    -- drops the row it was drawn on (and gives that row back to the text).
    vim.opt.shortmess:append 'WAIF'
    vim.o.cmdheight = 0
    vim.o.showcmd = false
    vim.o.ruler = false
    vim.o.report = 9999

    -- Line numbers stay (inherited from config/options.lua); the sign column is 2
    -- columns of the text area spent on signs nothing places in these buffers.
    vim.o.signcolumn = 'no'

    -- Matches the terminal profile's font. Firenvim floors the canvas to whole cells, so
    -- a cell this large leaves up to 16px of the text area unused on each axis.
    vim.o.guifont = 'Monospace:h16'

    -- Canvas's Rich Content Editor stores HTML (see the localSettings entry above), which
    -- is a miserable thing to write by hand. Pandoc converts between the two.
    --
    -- Pandoc's Markdown rather than GitHub's: a link carrying attributes Markdown has no
    -- syntax for -- and Canvas's links carry class, target and rel -- comes out of the gfm
    -- writer as a raw <a> tag, but as [text](url){.class target="_blank"} here, which
    -- survives the trip back intact. -auto_identifiers drops the id slug pandoc would
    -- otherwise attach to every heading.
    local MARKDOWN_IN = 'markdown-auto_identifiers'
    local MARKDOWN_OUT = 'markdown'
    local HTML = 'html'

    local function pandoc(from, to, lines)
      -- --wrap=none: the element is one soft-wrapping box, and hard breaks pandoc adds on
      -- one pass become paragraph text on the next. The filter drops TinyMCE's data-mce-*
      -- attributes, which duplicate the href and are rebuilt by the editor anyway.
      local cmd = { 'pandoc', '-f', from, '-t', to, '--wrap=none',
                    '-L', vim.fn.stdpath('config') .. '/pandoc/tinymce.lua' }
      local result = vim.system(cmd, { stdin = table.concat(lines, '\n') }):wait()
      if result.code ~= 0 then
        vim.notify('pandoc: ' .. (result.stderr or 'failed'), vim.log.levels.ERROR)
        return nil
      end
      local out = vim.trim(result.stdout)
      return out == '' and {} or vim.split(out, '\n')
    end

    -- :Md and :Html convert the buffer by hand, for a TinyMCE editor on some other site.
    -- Canvas buffers do it on their own; see below.
    local function rewrite(from, to, filetype)
      return function()
        local out = pandoc(from, to, vim.api.nvim_buf_get_lines(0, 0, -1, false))
        if out then
          vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
          vim.bo.filetype = filetype
        end
      end
    end

    vim.api.nvim_create_user_command('Md', rewrite(HTML, MARKDOWN_OUT, 'markdown'), { desc = 'Rewrite the buffer as Markdown' })
    vim.api.nvim_create_user_command('Html', rewrite(MARKDOWN_IN, HTML, 'html'), { desc = 'Rewrite the buffer as HTML' })

    -- A Canvas buffer is edited as Markdown and stored as HTML: it is converted once on
    -- arrival, and converted back on the way out. b:canvas_markdown marks a buffer that
    -- made that trip, and is what the sync below keys on.
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('firenvim-canvas', { clear = true }),
      callback = function(ev)
        if vim.b[ev.buf].canvas_markdown ~= nil then
          return
        end
        if not vim.fn.fnamemodify(ev.file, ':t'):match(canvas_buffer_pattern) then
          return
        end
        -- Set before converting, so a pandoc failure leaves the buffer as the HTML it
        -- already holds rather than retrying on every BufEnter.
        vim.b[ev.buf].canvas_markdown = false
        local md = pandoc(HTML, MARKDOWN_OUT, vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false))
        if md then
          vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, md)
          vim.bo[ev.buf].filetype = 'markdown'
          vim.b[ev.buf].canvas_markdown = true
        end
      end,
    })

    -- Write back to the text area as you type rather than only on :w. Firenvim pushes the
    -- buffer to the page from its own BufWrite autocmd, which a write from inside an
    -- autocmd only reaches when nesting is enabled -- without it the page keeps the
    -- content it had, and never resizes the text area to fit.
    --
    -- A Markdown buffer takes the other route: firenvim#write sends the lines it is given
    -- rather than the buffer's own, so the page receives HTML while the buffer stays
    -- Markdown. It is debounced, because a pandoc run per keystroke is work nobody sees --
    -- the page only has to be right once typing pauses.
    local function push_html(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local html = pandoc(MARKDOWN_IN, HTML, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
      if html then
        vim.fn['firenvim#write'](html, vim.api.nvim_win_get_cursor(0))
      end
    end

    local sync_timer
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      group = vim.api.nvim_create_augroup('firenvim-sync', { clear = true }),
      nested = true,
      callback = function(ev)
        if not vim.b[ev.buf].canvas_markdown then
          vim.cmd.write { mods = { silent = true, emsg_silent = true } }
          return
        end
        if sync_timer then
          sync_timer:stop()
        end
        sync_timer = vim.defer_fn(function()
          push_html(ev.buf)
        end, 300)
      end,
    })

    -- :w sends the buffer to the page on its own: Firenvim answers BufWrite -- that is,
    -- BufWritePre -- with an argument-less firenvim#write, which sends the buffer's own
    -- lines. Answering it with a second, corrected write does not work: on :wq Neovim exits
    -- before a notification sent from BufWritePost or VimLeavePre reaches the browser, and
    -- the Markdown from Firenvim's own write is what stays in the page.
    --
    -- So the buffer itself is HTML for the duration of the write, and Markdown again
    -- afterwards. That leaves one write, Firenvim's, carrying the right text. This autocmd
    -- is registered at startup and Firenvim's when the frame attaches, so this one runs
    -- first.
    local canvas_write = vim.api.nvim_create_augroup('firenvim-canvas-write', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = canvas_write,
      callback = function(ev)
        if not vim.b[ev.buf].canvas_markdown then
          return
        end
        local markdown = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
        local html = pandoc(MARKDOWN_IN, HTML, markdown)
        if html then
          vim.b[ev.buf].canvas_markdown_lines = markdown
          vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, html)
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = canvas_write,
      callback = function(ev)
        local markdown = vim.b[ev.buf].canvas_markdown_lines
        if markdown then
          vim.b[ev.buf].canvas_markdown_lines = nil
          vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, markdown)
          -- Restoring the Markdown dirties the buffer again, which would make :wq stop and
          -- complain about unsaved changes.
          vim.bo[ev.buf].modified = false
        end
      end,
    })

    -- Quitting without writing leaves the page holding whatever the last debounced sync
    -- sent, which is HTML but can be a few hundred milliseconds stale. This closes that gap
    -- when it can; the notification is best-effort, since Neovim may exit before it is
    -- delivered.
    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = canvas_write,
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.b[buf].canvas_markdown and vim.bo[buf].modified then
          local html = pandoc(MARKDOWN_IN, HTML, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
          if html then
            vim.fn['firenvim#write'](html, vim.api.nvim_win_get_cursor(0))
          end
        end
      end,
    })

    -- Per-site filetypes, matched against the buffer name Firenvim generates
    -- (<host>_<...>.txt).
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('firenvim-ft', { clear = true }),
      callback = function(ev)
        local name = vim.fn.fnamemodify(ev.file, ':t')
        if name:match '^github%.com' or name:match '^gitlab%.com' or name:match '^.*reddit%.com' then
          vim.bo.filetype = 'markdown'
        end
      end,
    })
  end,
}
