vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

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
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

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
end)
