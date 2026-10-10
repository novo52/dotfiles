-- Run by bootstrap.sh inside a headless nvim. The config builds treesitter
-- parsers in the background on startup, and a headless session that quits
-- straight away kills the builds part-way. This waits for them, installs the
-- language servers, then prints one summary line for the bootstrap to report.

local has_ts, ts = pcall(require, 'nvim-treesitter')

if TreesitterInstall then
  pcall(function()
    TreesitterInstall:wait(600000)
  end)
  -- A grammar whose download failed is simply absent afterwards, so ask once
  -- more for whatever is.
  local installed = {}
  for _, lang in ipairs(ts.get_installed()) do
    installed[lang] = true
  end
  local again = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, TreesitterMissing or {})
  if #again > 0 then
    pcall(function()
      ts.install(again):wait(600000)
    end)
  end
end

-- The config loads mason when a file is first read, which a headless session
-- never does, and mason-lspconfig's `ensure_installed` starts nothing without
-- a UI. So load it, read the server list back out of its settings, and install
-- through the API. :MasonInstall would do, except that headless it quits nvim
-- with an error as soon as one package fails.
local servers_wanted, servers_present = 0, 0
pcall(function()
  require('lazy').load { plugins = { 'mason-lspconfig.nvim' } }
  local registry = require 'mason-registry'
  -- Blocks until the package index has been downloaded; on a new machine
  -- nothing is known about any package before that.
  registry.refresh()
  local to_package = require('mason-lspconfig').get_mappings().lspconfig_to_package
  local packages = {}
  for _, server in ipairs(require('mason-lspconfig.settings').current.ensure_installed) do
    local found, pkg = pcall(registry.get_package, to_package[server])
    if found then
      packages[#packages + 1] = pkg
      if not pkg:is_installed() then
        pkg:install()
      end
    end
  end
  vim.wait(900000, function()
    for _, pkg in ipairs(packages) do
      if pkg:is_installing() then
        return false
      end
    end
    return true
  end, 500)
  servers_wanted = #packages
  for _, pkg in ipairs(packages) do
    if pkg:is_installed() then
      servers_present = servers_present + 1
    end
  end
end)

local parsers = 0
if has_ts then
  parsers = #ts.get_installed()
end

io.stdout:write(
  string.format(
    '\nprovisioned: %d plugins, %d parsers, %d of %d language servers\n',
    #require('lazy').plugins(),
    parsers,
    servers_present,
    servers_wanted
  )
)
