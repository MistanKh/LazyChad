local M = {}

local utils = require "configs.picker_utils"
local selection_ui = require "configs.selection_ui"

local state_path = vim.fn.stdpath "data" .. "/lint_picker_state.json"
local none_choice = "__none__"
local state = nil
local prompting = {}

local function load_state()
  if state then return state end
  state = utils.read_json(state_path) or { filetypes = {} }
  return state
end

local function save_state()
  utils.write_json(state_path, load_state())
end

local function set_linter(ft, linter)
  local ok, lint = pcall(require, "lint")
  if ok then
    lint.linters_by_ft[ft] = { linter }
    lint.try_lint()
  end
end

local function package_name_for(linter)
  local ok, lint = pcall(require, "lint")
  if not ok then return linter end
  local spec = lint.linters[linter]
  if not spec then return linter end
  local cmd = type(spec) == "table" and spec.cmd or linter
  if type(cmd) == "function" then cmd = cmd() end
  return utils.package_name_by_bin(cmd or linter)
end

function M.choose_for_filetype(ft)
  if not ft or ft == "" or prompting[ft] then return end
  prompting[ft] = true

  utils.on_registry_ready(function()
    local candidates = utils.get_mason_candidates(ft, "Linter")
    vim.list_extend(candidates, utils.get_builtins(ft, "Linter"))
    
    if #candidates == 0 then
      prompting[ft] = nil
      return
    end

    local recommended = utils.get_recommendation(ft, "Linter")
    
    local valid = {}
    local display_map = {}
    local seen = {}
    local ok, lint = pcall(require, "lint")
    
    if ok then
      for _, c in ipairs(candidates) do
        if not seen[c] then
          local tool = nil
          if lint.linters[c] then tool = c
          elseif lint.linters[c:gsub("%-", "")] then tool = c:gsub("%-", "")
          elseif lint.linters[c:gsub("%-", "_")] then tool = c:gsub("%-", "_")
          elseif vim.list_contains(utils.get_builtins(ft, "Linter"), c) then tool = c
          end

          if tool then
            seen[c] = true
            local label = tool
            if tool == recommended then
              label = tool .. " (Recommended)"
              table.insert(valid, 1, label)
            else
              table.insert(valid, label)
            end
            display_map[label] = tool
          end
        end
      end
    end

    if #valid == 0 then
      prompting[ft] = nil
      return
    end

    local items = { "None" }
    vim.list_extend(items, valid)

    selection_ui.select(items, {
      prompt = "Select linter for " .. ft,
      title = " Linter Picker ",
    }, function(choice)
      prompting[ft] = nil
      if not choice then return end

      local tool = display_map[choice] or choice
      local current = load_state()
      current.filetypes[ft] = (tool == "None") and none_choice or tool
      save_state()

      if tool ~= "None" then
        local builtins = utils.get_builtins(ft, "Linter")
        if vim.list_contains(builtins, tool) then
          set_linter(ft, tool)
        else
          utils.ensure_installed(package_name_for(tool), "linter", tool, function()
            set_linter(ft, tool)
          end)
        end
      end
    end)
  end)
end

local function get_saved_choice(ft)
  local state = load_state()
  if state.filetypes[ft] then return state.filetypes[ft] end
  local base = ft:match("^([^%.]+)")
  if base and state.filetypes[base] then return state.filetypes[base] end
  return nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("lint_picker", { clear = true })

  local function check_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local ft = vim.bo[buf].filetype
    if not ft or ft == "" or vim.bo[buf].buftype ~= "" then return end

    local saved = get_saved_choice(ft)
    if saved == none_choice then return end

    if saved and saved ~= "" then
      local is_builtin = vim.list_contains(utils.get_builtins(ft, "Linter"), saved)
      local is_installed = is_builtin
      local reg_ok, reg = pcall(require, "mason-registry")

      if not is_installed and reg_ok then
        local pkg_name = package_name_for(saved)
        if reg.has_package(pkg_name) and reg.get_package(pkg_name):is_installed() then
          is_installed = true
        end
      end

      if is_installed then
        vim.schedule(function()
          set_linter(ft, saved)
        end)
      else
        -- Clear and re-prompt
        local current = load_state()
        current.filetypes[ft] = nil
        save_state()
        vim.schedule(function() M.choose_for_filetype(ft) end)
      end
    else
      vim.schedule(function() M.choose_for_filetype(ft) end)
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      check_buffer(args.buf)
    end,
  })

  vim.schedule(function()
    check_buffer(vim.api.nvim_get_current_buf())
  end)

  vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
    group = group,
    callback = function()
      local ok, lint = pcall(require, "lint")
      if ok then lint.try_lint() end
    end,
  })

  vim.api.nvim_create_user_command("LintPick", function(opts)
    M.choose_for_filetype(opts.args ~= "" and opts.args or vim.bo.filetype)
  end, { nargs = "?" })
end

return M
