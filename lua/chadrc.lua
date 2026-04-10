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

    local status = count > 0 and "OPTIMIZED" or "INITIALIZING"
    
    return {
      "                                                               ",
      "      ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀  ",
      "               L  U  M  I  N  O  U  S    &    L  A  Z  Y       ",
      "      ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ",
      "                                                               ",
      "        _      ____  _____  __   __  ____ _   _  ____  ____    ",
      "       | |    / _  ||__  /  \\ \\ / / / ___| | | |/ _  ||  _ \\   ",
      "       | |   / /_| |  / /    \\ V / | |   | |_| / /_| || | | |  ",
      "       | |___|  _  | / /__    | |  | |___|  _  |  _  || |_| |  ",
      "       |_____|_| |_|/____|    |_|   \\____|_| |_|_| |_||____/   ",
      "                                                               ",
      "      ───────────────────────────────────────────────────────  ",
      "         STATUS: " .. string.format("%-12s", status) .. "  |  NEURAL MAPPINGS: " .. string.format("%-2d", count) .. "   ",
      "      ───────────────────────────────────────────────────────  ",
      "             NVCHAD v2.5 CORE  |  INTELLIGENT TOOLCHAIN      ",
      "                                                             ",
    }
  end,
  buttons = {
    {
      multicolumn = true,
      { txt = "󱐋  ", hl = "Number" },
      { txt = "New File", hl = "NvdashButtons", pad = "full" },
      { txt = "En", hl = "Number" },
      keys = "En",
      cmd = "ene!",
    },
    {
      multicolumn = true,
      { txt = "󰈞  ", hl = "Function" },
      { txt = "Find File", hl = "NvdashButtons", pad = "full" },
      { txt = "Ff", hl = "Function" },
      keys = "Ff",
      cmd = "Telescope find_files",
    },
    {
      multicolumn = true,
      { txt = "󰈚  ", hl = "String" },
      { txt = "Recent Files", hl = "NvdashButtons", pad = "full" },
      { txt = "Fo", hl = "String" },
      keys = "Fo",
      cmd = "Telescope oldfiles",
    },
    {
      multicolumn = true,
      { txt = "󰈭  ", hl = "Type" },
      { txt = "Find Word", hl = "NvdashButtons", pad = "full" },
      { txt = "Fw", hl = "Type" },
      keys = "Fw",
      cmd = "Telescope live_grep",
    },
    {
      multicolumn = true,
      { txt = "󱔗  ", hl = "Identifier" },
      { txt = "Pick Toolchain", hl = "NvdashButtons", pad = "full" },
      { txt = "Lp", hl = "Identifier" },
      keys = "Lp",
      cmd = "LspPick",
    },
    {
      multicolumn = true,
      { txt = "󱗆  ", hl = "Keyword" },
      { txt = "Respect NvChad", hl = "NvdashButtons", pad = "full" },
      { txt = "Nv", hl = "Keyword" },
      keys = "Nv",
      cmd = "echo 'NvChad: The aesthetic foundation of LazyChad!'",
    },
    {
      multicolumn = true,
      { txt = "󰄉  ", hl = "DiagnosticHint" },
      { txt = "Check Health", hl = "NvdashButtons", pad = "full" },
      { txt = "Ch", hl = "DiagnosticHint" },
      keys = "Ch",
      cmd = "checkhealth",
    },
    {
      multicolumn = true,
      { txt = "󰒲  ", hl = "Special" },
      { txt = "Lazy Status", hl = "NvdashButtons", pad = "full" },
      { txt = "Ls", hl = "Special" },
      keys = "Ls",
      cmd = "Lazy",
    },
  },
}

M.ui = {
  tabufline = {
    lazyload = false
  }
}

return M
