-- Run by bootstrap.sh inside a headless nvim. The config starts treesitter
-- parser builds and mason installs in the background on startup; a headless
-- session that quits straight away kills them part-way. This waits for both,
-- then prints one summary line for the bootstrap to report.

if TreesitterInstall then
  pcall(function()
    TreesitterInstall:wait(600000)
  end)
end

local mason_names = {}
local ok, registry = pcall(require, 'mason-registry')
if ok then
  local function installing()
    for _, pkg in ipairs(registry.get_all_packages()) do
      if pkg:is_installing() then
        return true
      end
    end
    return false
  end
  -- Installs begin only after the registry has been fetched, so allow time
  -- for one to appear before waiting for all of them to end.
  pcall(vim.wait, 30000, installing, 500)
  pcall(vim.wait, 900000, function()
    return not installing()
  end, 1000)
  mason_names = registry.get_installed_package_names()
end

local parsers = 0
local has_ts, ts = pcall(require, 'nvim-treesitter')
if has_ts then
  parsers = #ts.get_installed()
end

io.stdout:write(
  string.format('\nprovisioned: %d plugins, %d parsers, %d language servers\n', #require('lazy').plugins(), parsers, #mason_names)
)
