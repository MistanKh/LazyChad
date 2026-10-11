local M = {}

local registry_bin_cache = nil
local failure_blacklist = {}

function M.read_json(path)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end
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
  if not fd then
    return
  end
  vim.uv.fs_write(fd, vim.json.encode(data), 0)
  vim.uv.fs_close(fd)
end

local recommendations = {
  LSP = {
    lua = "lua_ls",
    python = "basedpyright",
    javascript = "ts_ls",
    typescript = "ts_ls",
    javascriptreact = "ts_ls",
    typescriptreact = "ts_ls",
    vue = "vue_ls",
    svelte = "svelte",
    go = "gopls",
    rust = "rust_analyzer",
    c = "clangd",
    cpp = "clangd",
    java = "jdtls",
    kotlin = "kotlin_language_server",
    php = "intelephense",
    ruby = "ruby_lsp",
    elixir = "elixirls",
    haskell = "hls",
    zig = "zls",
    nix = "nil_ls",
    sh = "bashls",
    bash = "bashls",
    html = "html",
    css = "cssls",
    scss = "cssls",
    less = "cssls",
    json = "jsonls",
    yaml = "yamlls",
    toml = "taplo",
    markdown = "marksman",
    dockerfile = "dockerls",
    terraform = "terraformls",
  },
  Formatter = {
    lua = "stylua",
    python = "ruff_format",
    javascript = "prettierd",
    typescript = "prettierd",
    javascriptreact = "prettierd",
    typescriptreact = "prettierd",
    vue = "prettierd",
    svelte = "prettierd",
    json = "prettierd",
    yaml = "prettierd",
    markdown = "prettierd",
    html = "prettierd",
    css = "prettierd",
    scss = "prettierd",
    go = "goimports",
    rust = "rustfmt",
    c = "clang-format",
    cpp = "clang-format",
    java = "google-java-format",
    kotlin = "ktlint",
    php = "php_cs_fixer",
    ruby = "rubocop",
    nix = "nixfmt",
    toml = "taplo",
    sql = "sql_formatter",
    sh = "shfmt",
    bash = "shfmt",
  },
  Linter = {
    lua = "selene",
    python = "ruff",
    javascript = "eslint_d",
    typescript = "eslint_d",
    javascriptreact = "eslint_d",
    typescriptreact = "eslint_d",
    vue = "eslint_d",
    css = "stylelint",
    scss = "stylelint",
    markdown = "markdownlint",
    yaml = "yamllint",
    json = "jsonlint",
    dockerfile = "hadolint",
    terraform = "tflint",
    kotlin = "ktlint",
    ruby = "rubocop",
    sql = "sqlfluff",
    sh = "shellcheck",
    bash = "shellcheck",
    go = "golangcilint",
  },
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
  },
}

-- Builtins that a default toolchain doesn't always ship: only treat them as
-- builtin when they actually run (rustup's rust-analyzer proxy exists but
-- errors until `rustup component add rust-analyzer`), otherwise Mason installs.
local probe = {
  rust_analyzer = { "rust-analyzer", "--version" },
}
local probe_cache = {}

local function builtin_runs(name)
  local cmd = probe[name]
  if not cmd then
    return true
  end
  if probe_cache[name] == nil then
    local ok, res = pcall(function()
      return vim.system(cmd, { text = true }):wait(5000)
    end)
    probe_cache[name] = ok and res and res.code == 0 or false
  end
  return probe_cache[name]
end

-- false for a known tool whose binary exists but doesn't run (e.g. rustup's
-- rust-analyzer proxy without the component); true otherwise.
function M.tool_runs(name)
  return builtin_runs(name)
end

function M.get_builtins(ft, category)
  local cat = builtins[category]
  if not cat then
    return {}
  end
  local list = cat[ft:match "^([^%.]+)"] or cat[ft] or {}
  return vim.tbl_filter(builtin_runs, list)
end

function M.get_recommendation(ft, category)
  local cat = recommendations[category]
  if not cat then
    return nil
  end
  return cat[ft:match "^([^%.]+)"] or cat[ft]
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

-- Picker ordering. The old comparator returned true for (rec, rec), which
-- LuaJIT's table.sort can reject with "invalid order function for sorting".
function M.sort_recommended_first(labels)
  table.sort(labels, function(a, b)
    local ra = a:find("(Recommended)", 1, true) ~= nil
    local rb = b:find("(Recommended)", 1, true) ~= nil
    if ra ~= rb then
      return ra
    end
    return a < b
  end)
  local first = labels[1]
  return (first and first:find("(Recommended)", 1, true)) and first or nil
end

-- Auto-pick: true = always take the recommended tool without asking,
-- false = always ask, nil (default) = ask, offering the "always" item.
local settings_path = vim.fn.stdpath "data" .. "/lazychad_settings.json"
M.AUTO_LABEL = "* Always use the recommended tools"

function M.auto_pick()
  return (M.read_json(settings_path) or {}).auto_pick
end

function M.set_auto_pick(value)
  local settings = M.read_json(settings_path) or {}
  settings.auto_pick = value
  M.write_json(settings_path, settings)
end

-- Items for a picker (+ the selection_ui auto hook) given the sorted labels.
function M.picker_items(labels, rec_label)
  local items = {}
  if rec_label and M.auto_pick() == nil then
    items[#items + 1] = M.AUTO_LABEL
  end
  items[#items + 1] = "None"
  vim.list_extend(items, labels)
  local auto = rec_label and function()
    return M.auto_pick() == true and rec_label or nil
  end or nil
  return items, auto
end

-- Turn the "always" item into the recommended label and announce automatic picks.
function M.resolve_choice(choice, rec_label, auto, what, ft, command)
  if choice == M.AUTO_LABEL then
    M.set_auto_pick(true)
    vim.notify "LazyChad: using recommended tools from now on (:LazyChadAutoPick off to choose yourself)"
    return rec_label
  end
  if auto and choice then
    local name = choice:gsub(" %(Recommended%)$", "")
    vim.notify(("LazyChad: %s %s for %s (recommended; change with :%s)"):format(name, what, ft, command))
  end
  return choice
end

function M.on_registry_ready(callback)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    callback()
    return
  end

  if #registry.get_all_package_names() > 0 then
    callback()
  else
    registry.refresh(vim.schedule_wrap(callback))
  end
end

function M.get_mason_candidates(ft, category)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    return {}
  end

  local packages = registry.get_all_packages()
  local ft_base = ft:match "^([^%.]+)" or ft
  local mapped_ft = ft_mappings[ft_base] or ft_base

  return vim
    .iter(packages)
    :filter(function(pkg)
      local spec = pkg.spec
      if not spec.categories or not spec.languages then
        return false
      end

      local has_category = vim.iter(spec.categories):any(function(cat)
        return cat:lower() == category:lower()
      end)

      if not has_category then
        return false
      end

      return vim.iter(spec.languages):any(function(lang)
        local l = lang:lower():gsub(" ", "")
        return l == ft_base:lower() or l == ft:lower() or l == mapped_ft:lower()
      end)
    end)
    :map(function(pkg)
      if category == "LSP" and pkg.spec.neovim and pkg.spec.neovim.lspconfig then
        return pkg.spec.neovim.lspconfig
      end
      return pkg.name
    end)
    :totable()
end

function M.package_name_by_bin(bin_name)
  -- Tools may resolve to an absolute path (e.g. <project>/node_modules/.bin/prettier)
  bin_name = vim.fs.basename(bin_name)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    return bin_name
  end

  if registry.has_package(bin_name) then
    return bin_name
  end

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

  if failure_blacklist[pkg_name] then
    return
  end

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

  pkg:once(
    "install:success",
    vim.schedule_wrap(function()
      failure_blacklist[pkg_name] = nil
      vim.notify("Installed " .. display_name .. " successfully", vim.log.levels.INFO)
      callback()
    end)
  )

  pkg:once(
    "install:failed",
    vim.schedule_wrap(function()
      failure_blacklist[pkg_name] = true
      vim.notify(
        "Mason failed to install " .. pkg_name .. ". Auto-setup disabled for this tool. Check :Mason",
        vim.log.levels.ERROR
      )
    end)
  )

  if not pkg:is_installing() then
    pkg:install()
  end
end

return M
