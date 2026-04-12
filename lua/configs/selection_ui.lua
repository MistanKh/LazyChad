local M = {}

local queue = {}
local active = nil

local function close_active()
  if not active then return end
  local a = active
  active = nil -- Clear before acting to prevent recursion
  
  if a.win and vim.api.nvim_win_is_valid(a.win) then
    vim.api.nvim_win_close(a.win, true)
  end
  if a.buf and vim.api.nvim_buf_is_valid(a.buf) then
    vim.api.nvim_buf_delete(a.buf, { force = true })
  end
end

local function run_next()
  if active or #queue == 0 then return end
  
  local req = table.remove(queue, 1)
  local items = req.items
  local opts = req.opts or {}
  local callback = req.callback

  local display = {}
  local header = " " .. (opts.prompt or "Select") .. " "
  display[1] = header
  display[2] = string.rep("─", math.max(30, vim.fn.strdisplaywidth(header) + 4))

  for _, item in ipairs(items) do
    table.insert(display, "  " .. tostring(item))
  end

  local width = 0
  for _, line in ipairs(display) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = width + 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local height = #display
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    title = opts.title or " Picker ",
    title_pos = "center",
  })

  active = { buf = buf, win = win, callback = callback, items = items }
  
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:Keyword,CursorLine:Visual"
  vim.api.nvim_win_set_cursor(win, { 3, 2 })

  local finished = false
  local function finish(choice)
    if finished then return end
    finished = true
    close_active()
    if callback then callback(choice) end
    vim.schedule(run_next)
  end

  -- Ensure we cleanup and run next if buffer is closed by other means
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    once = true,
    callback = function()
      if not finished then
        finished = true
        active = nil
        if callback then callback(nil) end
        vim.schedule(run_next)
      end
    end,
  })

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
  end

  -- Fix E21 by mapping any potential modifiable operations to no-op
  map("i", "<Nop>")
  map("a", "<Nop>")
  map("r", "<Nop>")
  map("v", "<Nop>")
  map("x", "<Nop>")
  map("s", "<Nop>")
  map("o", "<Nop>")
  map("p", "<Nop>")
  map("d", "<Nop>")
  map("c", "<Nop>")
  map("u", "<Nop>")

  map("j", function()
    local curr = vim.api.nvim_win_get_cursor(win)[1]
    if curr < height then vim.api.nvim_win_set_cursor(win, { curr + 1, 2 }) end
  end)

  map("k", function()
    local curr = vim.api.nvim_win_get_cursor(win)[1]
    if curr > 3 then vim.api.nvim_win_set_cursor(win, { curr - 1, 2 }) end
  end)

  map("<CR>", function()
    local curr = vim.api.nvim_win_get_cursor(win)[1]
    finish(items[curr - 2])
  end)

  map("q", function() finish(nil) end)
  map("<Esc>", function() finish(nil) end)
end

function M.select(items, opts, callback)
  table.insert(queue, { items = items, opts = opts, callback = callback })
  run_next()
end

return M
