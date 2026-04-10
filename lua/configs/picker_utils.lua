local M = {}

local registry_bin_cache = nil
local failure_blacklist = {}

function M.read_json(path)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then return nil end
  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return nil
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  local ok, decoded = pcall(vim.json.decode, data)
  return ok and decoded or nil
end

function M.write_json(path, data)
  local fd = vim.uv.fs_open(path, "w", 420)
  if not fd then return end
  vim.uv.fs_write(fd, vim.json.encode(data), 0)
  vim.uv.fs_close(fd)
end

local recommendations = {
  LSP = {
    lua = "lua_ls",
    python = "basedpyright",
    javascript = "ts_ls",
    typescript = "ts_ls",
    go = "gopls",
    rust = "rust_analyzer",
    html = "html",
    css = "cssls",
    json = "jsonls",
    yaml = "yamlls",
  },
  Formatter = {
    lua = "stylua",
    python = "ruff_format",
    javascript = "prettierd",
    typescript = "prettierd",
    json = "prettierd",
    html = "prettierd",
    go = "goimports",
    rust = "rustfmt",
    sh = "shfmt",
  },
  Linter = {
    lua = "selene",
    python = "ruff",
    javascript = "eslint_d",
    typescript = "eslint_d",
    sh = "shellcheck",
    go = "golangcilint",
  }
}

local builtins = {
  LSP = {
    rust = { "rust_analyzer" },
  },
  Formatter = {
    rust = { "rustfmt" },
  },
  Linter = {
    rust = { "clippy" },
  }
}

function M.get_builtins(ft, category)
  local cat = builtins[category]
  if not cat then return {} end
  return cat[ft:match("^([^%.]+)")] or cat[ft] or {}
end

function M.get_recommendation(ft, category)
  local cat = recommendations[category]
  if not cat then return nil end
  return cat[ft:match("^([^%.]+)")] or cat[ft]
end

local ft_mappings = {
  cs = "c#",
  cpp = "c++",
  sh = "shell",
  bash = "shell",
  zsh = "shell",
  javascriptreact = "javascript",
  typescriptreact = "typescript",
  ["c++"] = "c++",
  ["c#"] = "c#",
  c = "c",
  java = "java",
  php = "php",
  ruby = "ruby",
  rust = "rust",
  python = "python",
}

function M.get_mason_candidates(ft, category)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then return {} end
  
  local candidates = {}
  local packages = registry.get_all_packages()
  
  local ft_base = ft:match("^([^%.]+)") or ft
  local mapped_ft = ft_mappings[ft_base] or ft_base
  
  for _, pkg in ipairs(packages) do
    local spec = pkg.spec
    local is_match = false
    
    local has_category = false
    if spec.categories then
      for _, cat in ipairs(spec.categories) do
        if cat:lower() == category:lower() then
          has_category = true
          break
        end
      end
    end
    
    if has_category and spec.languages then
      for _, lang in ipairs(spec.languages) do
        local l = lang:lower():gsub(" ", "")
        if l == ft_base:lower() or l == ft:lower() or l == mapped_ft:lower() then
          is_match = true
          break
        end
      end
    end
    
    if is_match then
      if category == "LSP" and spec.neovim and spec.neovim.lspconfig then
        table.insert(candidates, spec.neovim.lspconfig)
      else
        table.insert(candidates, pkg.name)
      end
    end
  end
  
  table.sort(candidates)
  return candidates
end

function M.package_name_by_bin(bin_name)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then return bin_name end
  
  if registry.has_package(bin_name) then return bin_name end

  if not registry_bin_cache then
    registry_bin_cache = {}
    for _, name in ipairs(registry.get_all_package_names()) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and pkg and pkg.spec and type(pkg.spec.bin) == "table" then
        for b, _ in pairs(pkg.spec.bin) do
          registry_bin_cache[b] = name
        end
      end
    end
  end
  
  return registry_bin_cache[bin_name] or bin_name
end

function M.is_blacklisted(pkg_name)
  return failure_blacklist[pkg_name] == true
end

function M.clear_blacklist(pkg_name)
  failure_blacklist[pkg_name] = nil
end

function M.ensure_installed(pkg_name, tool_type, display_name, callback)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    callback()
    return
  end

  if failure_blacklist[pkg_name] then return end

  if not registry.has_package(pkg_name) then
    vim.notify("Package " .. pkg_name .. " not found in Mason", vim.log.levels.WARN)
    callback()
    return
  end

  local pkg = registry.get_package(pkg_name)
  if pkg:is_installed() then
    callback()
    return
  end

  vim.notify("Installing " .. tool_type .. " " .. display_name .. " via Mason", vim.log.levels.INFO)

  pkg:once("install:success", vim.schedule_wrap(function()
    failure_blacklist[pkg_name] = nil
    vim.notify("Installed " .. display_name .. " successfully", vim.log.levels.INFO)
    callback()
  end))

  pkg:once("install:failed", vim.schedule_wrap(function()
    failure_blacklist[pkg_name] = true
    vim.notify("Mason failed to install " .. pkg_name .. ". Auto-setup disabled for this tool. Check :Mason", vim.log.levels.ERROR)
  end))

  if not pkg:is_installing() then
    pkg:install()
  end
end

return M
