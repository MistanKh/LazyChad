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
vim.opt.ttimeoutlen = 10
vim.opt.timeoutlen = 500
vim.o.termguicolors = true

-- The "Nuclear Option": Stop Neovim from querying terminal capabilities entirely
-- This prevents the terminal from ever sending the +q4D73 response.
vim.cmd([[
  let &t_u7 = ""
  let &t_TI = ""
  let &t_TE = ""
]])

-- Final safety: Clear any leaked characters if they still managed to get in during the first 50ms
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.mode() == "n" then
      vim.schedule(function()
        vim.cmd("silent! normal! \x1b") -- Send an ESC to flush any partial escape sequences
      end)
    end
  end,
})

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
