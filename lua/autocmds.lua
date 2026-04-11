pcall(require, "nvchad.autocmds")

local ts_install_group = vim.api.nvim_create_augroup("ts_auto_install", { clear = true })
local ts_installing = {}

local function install_ts(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then return end

  local ft = vim.bo[buf].filetype
  if ft == nil or ft == "" or vim.bo[buf].buftype ~= "" then return end

  local lang = vim.treesitter.language.get_lang(ft) or ft
  if ts_installing[lang] then return end

  -- Check if parser is already installed
  local ok_configs, ts_configs = pcall(require, "nvim-treesitter.configs")
  if ok_configs then
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    if not parser_config[lang] then return end -- No parser exists for this lang
  end

  if vim.list_contains(ts.get_installed("parsers"), lang) then return end

  ts_installing[lang] = true

  vim.schedule(function()
    -- Use the official Ex command for maximum reliability across versions
    local ok = pcall(vim.cmd, "TSInstall " .. lang)
    
    -- Clear the installing flag after a generous timeout to allow async install to finish
    vim.defer_fn(function()
      ts_installing[lang] = nil
    end, 15000)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group = ts_install_group,
  pattern = "*",
  callback = function(args)
    install_ts(args.buf)
  end,
})

-- Immediate check for the current buffer on boot
vim.schedule(function()
  install_ts(vim.api.nvim_get_current_buf())
end)
