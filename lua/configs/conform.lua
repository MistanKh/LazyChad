local utils = require "configs.picker_utils"

local state_path = vim.fn.stdpath "data" .. "/formatter_picker_state.json"
local none_choice = "__none__"

-- Mason package names that conform knows under another name. conform's
-- "ruff" is the old alias of ruff_fix (`ruff check --fix`), not a formatter.
local aliases = { ruff = "ruff_format" }

local function saved_choices()
  local state = utils.read_json(state_path)
  return (state and state.filetypes) or {}
end

local function choice_for(choices, ft)
  return choices[ft] or choices[ft:match "^([^%.]+)" or ft]
end

local function load_formatters()
  local formatters = {}
  for ft, tool in pairs(saved_choices()) do
    if tool ~= none_choice then
      formatters[ft] = { aliases[tool] or tool }
    end
  end
  return formatters
end

local options = {
  formatters_by_ft = load_formatters(),

  -- A function, so choosing "None" in :FormatPick also stops the LSP
  -- fallback from formatting that filetype on save.
  format_on_save = function(bufnr)
    if choice_for(saved_choices(), vim.bo[bufnr].filetype) == none_choice then
      return
    end
    return {
      timeout_ms = 1000,
      lsp_format = "fallback",
    }
  end,
}

return options
