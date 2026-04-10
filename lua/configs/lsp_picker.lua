local M = {}

local utils = require "configs.picker_utils"
local selection_ui = require "configs.selection_ui"
local registry_ok, registry = pcall(require, "mason-registry")

local state_path = vim.fn.stdpath "data" .. "/lsp_picker_state.json"
local none_choice = "__none__"
local state = nil
local prompting = {}
local server_specs = nil

-- NvChad's standard LSP setup
local nv_lsp = require "nvchad.configs.lspconfig"
local on_attach = nv_lsp.on_attach
local on_init = nv_lsp.on_init
local capabilities = nv_lsp.capabilities

local package_aliases = {
  html = "html-lsp",
  cssls = "css-lsp",
  lua_ls = "lua-language-server",
  tsserver = "typescript-language-server",
  bashls = "bash-language-server",
  jsonls = "json-lsp",
  yamlls = "yaml-language-server",
  dockerls = "dockerfile-language-server",
}

local function load_state()
  if state then return state end
  state = utils.read_json(state_path) or { filetypes = {} }
  return state
end

local function save_state()
  utils.write_json(state_path, load_state())
end

local function get_server_specs()
  if server_specs then return server_specs end
  local path = vim.fn.stdpath "data" .. "/lazy/nvim-lspconfig/lsp"
  local files = vim.fn.globpath(path, "*.lua", false, true)
  local specs = {}
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local chunk = loadfile(file)
    if chunk then
      local ok, spec = pcall(chunk)
      if ok and type(spec) == "table" then specs[name] = spec end
    end
  end
  server_specs = specs
  return server_specs
end

local setup_servers = {}

local package_name_cache = {}

local function package_name_for(server)
  if package_aliases[server] then return package_aliases[server] end
  if package_name_cache[server] then return package_name_cache[server] end
  if not registry_ok then return server end
  
  -- Fast check
  if registry.has_package(server) then 
    package_name_cache[server] = server
    return server 
  end
  
  -- Fallback search (find package that provides this lspconfig name)
  for _, name in ipairs(registry.get_all_package_names()) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and pkg and pkg.spec and pkg.spec.neovim and pkg.spec.neovim.lspconfig == server then
      package_name_cache[server] = name
      return name
    end
  end
  
  return server
end

local function setup_server(server)
  if setup_servers[server] then return end
  
  -- Ensure lspconfig is loaded once to populate vim.lsp.config
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if not ok_lsp then return end
  
  if vim.lsp.config then
    local config = vim.lsp.config[server]
    if config then
      config.on_attach = on_attach
      config.on_init = on_init
      
      -- Merge capabilities
      config.capabilities = vim.tbl_deep_extend("force", config.capabilities or {}, capabilities)
      
      -- Start the server using the new API
      vim.lsp.enable(server)
      
      setup_servers[server] = true
      return
    end
  end

  -- Fallback if vim.lsp.config is not supported (older Neovim versions)
  local config = lspconfig[server]
  if config then
     config.setup {
       on_attach = on_attach,
       on_init = on_init,
       capabilities = capabilities,
       root_dir = function(fname)
         local util = require("lspconfig.util")
         return util.find_git_ancestor(fname) or vim.loop.cwd()
       end,
     }
     setup_servers[server] = true
  end
end

function M.choose_for_filetype(ft)
  if not ft or ft == "" or prompting[ft] then return end
  
  local candidates = utils.get_mason_candidates(ft, "LSP")
  -- Include builtins (like rust_analyzer)
  vim.list_extend(candidates, utils.get_builtins(ft, "LSP"))
  
  local specs = get_server_specs()
  local recommended = utils.get_recommendation(ft, "LSP")
  
  local valid = {}
  local display_map = {}
  local seen = {}
  
  for _, c in ipairs(candidates) do
    if not seen[c] and specs[c] then
      seen[c] = true
      local label = c
      if c == recommended then
        label = c .. " (Recommended)"
        table.insert(valid, 1, label)
      else
        table.insert(valid, label)
      end
      display_map[label] = c
    end
  end

  if #valid == 0 then return end

  prompting[ft] = true
  local items = { "None" }
  vim.list_extend(items, valid)

  selection_ui.select(items, {
    prompt = "Select LSP for " .. ft,
    title = " LSP Picker ",
  }, function(choice)
    prompting[ft] = nil
    if not choice then return end
    
    local server = display_map[choice] or choice
    local current = load_state()
    current.filetypes[ft] = (server == "None") and none_choice or server
    save_state()

    if server ~= "None" then
      local builtins = utils.get_builtins(ft, "LSP")
      if vim.list_contains(builtins, server) then
        setup_server(server)
      else
        utils.ensure_installed(package_name_for(server), "LSP", server, function()
          setup_server(server)
        end)
      end
    end
  end)
end

local function get_saved_choice(ft)
  local state = load_state()
  if state.filetypes[ft] then return state.filetypes[ft] end
  
  -- Check base filetype (e.g., 'javascript' for 'javascript.jsx')
  local base = ft:match("^([^%.]+)")
  if base and state.filetypes[base] then return state.filetypes[base] end
  
  return nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("lsp_picker", { clear = true })
  
  local function check_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local ft = vim.bo[buf].filetype
    if not ft or ft == "" or vim.bo[buf].buftype ~= "" then return end
    
    local saved = get_saved_choice(ft)
    if saved == none_choice then return end
    
    if saved and saved ~= "" then
      local is_builtin = vim.list_contains(utils.get_builtins(ft, "LSP"), saved)
      local is_installed = is_builtin
      
      if not is_installed and registry_ok then
        local pkg_name = package_name_for(saved)
        if registry.has_package(pkg_name) and registry.get_package(pkg_name):is_installed() then
          is_installed = true
        end
      end

      if is_installed then
        vim.schedule(function()
          setup_server(saved)
        end)
      else
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

  -- Immediate check for the current buffer
  vim.schedule(function()
    check_buffer(vim.api.nvim_get_current_buf())
  end)

  vim.api.nvim_create_user_command("LspPick", function(opts)
    M.choose_for_filetype(opts.args ~= "" and opts.args or vim.bo.filetype)
  end, { nargs = "?" })
end

return M
