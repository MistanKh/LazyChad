-- Silence nvim-lspconfig deprecation warnings for Neovim 0.10.x
vim.g.lspconfig_silence_deprecation = true

-- defaults() enables lua_ls unconditionally. When Lua has a different
-- :LspPick choice (another server, or None), keep it from starting at all.
local ok_picker, picker = pcall(require, "configs.lsp_picker")
local lua_choice = ok_picker and picker.lua_choice() or nil
local enable = vim.lsp.enable
if enable and lua_choice and lua_choice ~= "lua_ls" then
  vim.lsp.enable = function(name, ...)
    if type(name) == "table" then
      name = vim.tbl_filter(function(n)
        return n ~= "lua_ls"
      end, name)
    elseif name == "lua_ls" then
      return
    end
    return enable(name, ...)
  end
end

-- Safely call defaults, as it may try to access vim.lsp.config (0.11+ feature)
pcall(function()
  require("nvchad.configs.lspconfig").defaults()
end)
vim.lsp.enable = enable

-- Belt and braces: stop a lua_ls that was started anyway.
if ok_picker then
  pcall(picker.apply_lua_choice)
end
