require "nvchad.options"

-- Silence all Neovim deprecation warnings (especially for stylize_markdown in 0.11+)
vim.g.deprecation_warnings = false
-- Suppress specific internal deprecation notices
pcall(function()
  vim.deprecate = function() end
end)

-- Fix terminal query leaks (like +q4D73) on some terminal emulators
-- This happens when the terminal responds to a query before Neovim is ready
vim.o.ttyfast = true
vim.o.lazyredraw = true
vim.opt.ttimeoutlen = 10 -- Shorter timeout to distinguish terminal codes from typed keys
vim.opt.timeoutlen = 500  -- Faster leader/mapping timeouts

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
