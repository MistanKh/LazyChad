-- Silence nvim-lspconfig deprecation warnings for Neovim 0.10.x
vim.g.lspconfig_silence_deprecation = true

-- Safely call defaults, as it may try to access vim.lsp.config (0.11+ feature)
pcall(function()
  require("nvchad.configs.lspconfig").defaults()
end)
