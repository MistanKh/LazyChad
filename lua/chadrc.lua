---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "rosepine",

	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}

M.nvdash = {
  load_on_startup = true,
  header = function()
    local ok, utils = pcall(require, "configs.picker_utils")
    local count = 0
    if ok then
      local state = utils.read_json(vim.fn.stdpath "data" .. "/lsp_picker_state.json") or {}
      count = vim.tbl_count(state.filetypes or {})
    end

    return {
      "                                                     ",
      "                ▀ LUMINOUS & LAZY ▀                  ",
      "                                                     ",
      "   __                      ________             __   ",
      "  / /   ____ _____ __  __ / ____/ /_  ____ _____/ /   ",
      " / /   / __ `/_  // / / // /   / __ \\/ __ `/ __  /    ",
      "/ /___/ /_/ / / / / /_/ // /___/ / / / /_/ / /_/ /     ",
      "/_____/\\__,_/ /___/\\__, / \\____/_/ /_/\\__,_/\\__,_/      ",
      "                  /____/                             ",
      "                                                     ",
      "          󱐋 " .. count .. " INTELLIGENT NEURAL MAPPINGS          ",
      "                                                     ",
      "   ╭───────────────────────────────────────────────╮ ",
      "   │  Built with 󱗆  Passion on the NvChad Platform  │ ",
      "   ╰───────────────────────────────────────────────╯ ",
      "                                                     ",
    }
  end,
  buttons = {
    { txt = "󱐋  New File", keys = "En", cmd = "ene!" },
    { txt = "󰈞  Find File", keys = "Ff", cmd = "Telescope find_files" },
    { txt = "󰈚  Recent Files", keys = "Fo", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Find Word", keys = "Fw", cmd = "Telescope live_grep" },
    { txt = "󱔗  Pick Toolchain", keys = "Lp", cmd = "LspPick" },
    { txt = "󱗆  Respect NvChad", keys = "Nv", cmd = "echo 'NvChad: The aesthetic foundation of LazyChad!'" },
    { txt = "󰄉  Check Health", keys = "Ch", cmd = "checkhealth" },
    { txt = "󰒲  Lazy Status", keys = "Ls", cmd = "Lazy" },
  },
}

M.ui = {
  tabufline = {
    lazyload = false
  }
}

return M
