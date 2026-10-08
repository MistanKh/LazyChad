-- One-time headless setup, run by `lchad --bootstrap` (and by lazychad-deps)
-- so the first interactive launch opens straight into a working editor.
local M = {}

-- Base tools for editing the Neovim config itself
M.mason_packages = { "lua-language-server", "stylua" }

M.treesitter_parsers = { "vim", "lua", "vimdoc", "html", "css", "python" }

local function say(msg)
  io.stdout:write("  " .. msg .. "\n")
end

local function install_mason_packages(timeout_ms)
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    pcall(lazy.load, { plugins = { "mason.nvim" } })
  end

  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return { "mason.nvim is not available" }
  end

  local refreshed = false
  registry.refresh(function()
    refreshed = true
  end)
  vim.wait(60000, function()
    return refreshed
  end, 200)

  local pending, failed = {}, {}
  for _, name in ipairs(M.mason_packages) do
    if not registry.has_package(name) then
      table.insert(failed, name .. " (not in the Mason registry)")
    else
      local pkg = registry.get_package(name)
      if pkg:is_installed() then
        say("✅ " .. name .. " already installed")
      else
        say("Installing " .. name .. " via Mason...")
        pending[name] = true
        pkg:once("install:success", function()
          pending[name] = nil
          say("✅ " .. name .. " installed")
        end)
        pkg:once("install:failed", function()
          pending[name] = nil
          table.insert(failed, name)
        end)
        if not pkg:is_installing() then
          pkg:install()
        end
      end
    end
  end

  local done = vim.wait(timeout_ms, function()
    return next(pending) == nil
  end, 500)
  if not done then
    for name in pairs(pending) do
      table.insert(failed, name .. " (timed out)")
    end
  end
  return failed
end

local function install_parsers(timeout_ms)
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    pcall(lazy.load, { plugins = { "nvim-treesitter" } })
  end

  local ok, ts = pcall(require, "nvim-treesitter")
  if ok and type(ts.install) == "function" then
    -- nvim-treesitter `main` branch: async install with a waitable task. A
    -- parser that fails to build is only logged, so check what got installed.
    local ok_install, err = pcall(function()
      return ts.install(M.treesitter_parsers):wait(timeout_ms)
    end)
    if not ok_install then
      return { "treesitter parsers: " .. tostring(err) }
    end
    local ok_list, installed = pcall(ts.get_installed, "parsers")
    if not ok_list then
      return {}
    end
    local missing = vim.tbl_filter(function(lang)
      return not vim.list_contains(installed, lang)
    end, M.treesitter_parsers)
    if #missing > 0 then
      return {
        "treesitter parsers failed to build: "
          .. table.concat(missing, ", ")
          .. " (needs a C compiler and the tree-sitter CLI)",
      }
    end
    return {}
  end

  if vim.fn.exists ":TSInstallSync" == 2 then
    -- `master` branch: only request missing parsers, so it never prompts to reinstall
    local parsers = require "nvim-treesitter.parsers"
    local missing = vim.tbl_filter(function(lang)
      return not parsers.has_parser(lang)
    end, M.treesitter_parsers)
    if #missing == 0 then
      return {}
    end
    local ok_install, err = pcall(vim.cmd, "TSInstallSync " .. table.concat(missing, " "))
    return ok_install and {} or { "treesitter parsers: " .. tostring(err) }
  end

  return { "nvim-treesitter is not available" }
end

function M.run()
  say "Installing Mason tools..."
  local failed = install_mason_packages(10 * 60 * 1000)

  say "Installing treesitter parsers..."
  vim.list_extend(failed, install_parsers(10 * 60 * 1000))

  if #failed > 0 then
    for _, f in ipairs(failed) do
      io.stderr:write("  ⚠️  " .. f .. "\n")
    end
    vim.cmd "cquit 1"
  end
  say "✅ Plugins and tools are ready."
  vim.cmd "qall!"
end

return M
