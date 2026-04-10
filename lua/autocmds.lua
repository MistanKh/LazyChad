require "nvchad.autocmds"

local ts_install_group = vim.api.nvim_create_augroup("ts_auto_install", { clear = true })
local ts_installing = {}

vim.api.nvim_create_autocmd("FileType", {
  group = ts_install_group,
  pattern = "*",
  callback = function(args)
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then
      return
    end

    local ft = vim.bo[args.buf].filetype
    if ft == nil or ft == "" then
      return
    end

    local lang = vim.treesitter.language.get_lang(ft) or ft
    if ts_installing[lang] then
      return
    end

    if not vim.list_contains(ts.get_available(), lang) then
      return
    end

    if vim.list_contains(ts.get_installed("parsers"), lang) then
      return
    end

    ts_installing[lang] = true

    local install_ok, install = pcall(ts.install, lang)
    if not install_ok then
      ts_installing[lang] = nil
      vim.schedule(function()
        vim.notify("Treesitter install failed for " .. lang, vim.log.levels.WARN)
      end)
      return
    end

    if install and install.await then
      install:await(function()
        ts_installing[lang] = nil
      end)
    else
      ts_installing[lang] = nil
    end
  end,
})
