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
      "                                                                        ",
      "    ╔════════════════════════════════════════════════════════════════╗  ",
      "    ║  [ SYSTEM: LAZYCHAD ]              [ AUTHOR: MISTAN KHOMDRAM ]  ║  ",
      "    ╚════════════════════════════════════════════════════════════════╝  ",
      "                                                                        ",
      "      ██╗      █████╗ ███████╗██╗   ██╗ ██████╗██╗  ██╗ █████╗ ██████╗  ",
      "      ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██╔════╝██║  ██║██╔══██╗██╔══██╗ ",
      "      ██║     ███████║  ███╔╝  ╚████╔╝ ██║     ███████║███████║██║  ██║ ",
      "      ██║     ██║  ██║ ███╔╝    ╚██╔╝  ██║     ██║  ██║██║  ██║██║  ██║ ",
      "      ███████╗██║  ██║███████╗   ██║   ╚██████╗██║  ██║██║  ██║██████╔╝ ",
      "      ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ",
      "                                                                        ",
      "    ──────────────────────────────────────────────────────────────────  ",
      "       INTELLIGENCE: " .. string.format("%-14s", status) .. "  |  NEURAL MAPPINGS: " .. string.format("%-2d", count) .. "   ",
      "    ──────────────────────────────────────────────────────────────────  ",
      "                                                                        ",
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
