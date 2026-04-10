require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>lp", "<cmd>LspPick<cr>", { desc = "Pick LSP" })
map("n", "<leader>fp", "<cmd>FormatPick<cr>", { desc = "Pick formatter" })
map("n", "<leader>tp", "<cmd>LintPick<cr>", { desc = "Pick linter" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
