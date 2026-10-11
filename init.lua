vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- Force termguicolors early to stop terminal query leaks
vim.opt.termguicolors = true

-- Ensure local modules are in the search path by prepending the config directory to rtp
vim.opt.rtp:prepend(vim.fn.stdpath "config")

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }):wait()
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
local specs = {
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}

-- Your own plugins: lua/user/plugins/*.lua (never overwritten by LazyChad)
if vim.uv.fs_stat(vim.fn.stdpath "config" .. "/lua/user/plugins") then
  table.insert(specs, { import = "user.plugins" })
end

require("lazy").setup(specs, lazy_config)

-- load theme
pcall(function()
  if vim.uv.fs_stat(vim.g.base46_cache .. "defaults") then
    dofile(vim.g.base46_cache .. "defaults")
    dofile(vim.g.base46_cache .. "statusline")
  end
end)

pcall(require, "options")
pcall(require, "autocmds")

-- Initialize Auto-Pickers
pcall(function()
  require("configs.lsp_picker").setup()
  require("configs.formatter_picker").setup()
  require("configs.lint_picker").setup()
end)

vim.schedule(function()
  pcall(require, "mappings")

  -- Your own settings and keymaps: lua/user/init.lua, loaded last so it wins
  local ok, err = pcall(require, "user")
  if not ok and not tostring(err):find("module 'user' not found", 1, true) then
    vim.notify("LazyChad: error in lua/user/init.lua:\n" .. tostring(err), vim.log.levels.ERROR)
  end
end)
