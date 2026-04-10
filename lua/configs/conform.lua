local M = {}

local function load_formatters()
  local state_path = vim.fn.stdpath "data" .. "/formatter_picker_state.json"
  local f = io.open(state_path, "r")
  if not f then return {} end
  local content = f:read "*a"
  f:close()
  local ok, state = pcall(vim.json.decode, content)
  if not ok or not state or not state.filetypes then return {} end
  
  local formatters = {}
  for ft, tool in pairs(state.filetypes) do
    if tool ~= "__none__" then
      formatters[ft] = { tool }
    end
  end
  return formatters
end

local options = {
  formatters_by_ft = load_formatters(),

  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
}

return options
