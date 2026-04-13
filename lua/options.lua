require "nvchad.options"

-- Silence all Neovim deprecation warnings (especially for stylize_markdown in 0.11+)
vim.g.deprecation_warnings = false
-- Suppress specific internal deprecation notices
pcall(function()
  vim.deprecate = function() end
end)

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Neovide config
if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h10"
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_opacity = 1.0
  vim.g.neovide_refresh_rate = 120
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_cursor_antialiasing = true
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
  vim.g.neovide_cursor_vfx_particle_density = 3.0
  vim.g.neovide_padding_top = 6
  vim.g.neovide_padding_bottom = 6
  vim.g.neovide_padding_right = 6
  vim.g.neovide_padding_left = 6
end
