local M = {}

local base_date = "2025-08-14"
local base_dtl = 18217

local diary_dirs = {
  vim.fs.normalize(vim.fn.expand("~/documents/notes/diary/")),
  vim.fs.normalize(vim.fn.expand("~/notes/diary/")),
}

local function lower_path(path)
  return path:gsub("\\", "/"):lower()
end

local triggers = {
  date = true,
  diaryHeader = true,
}

local function parse_date(date)
  local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not year then
    return nil
  end

  return {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
  }
end

local function day_number(date)
  local parts = parse_date(date)
  if not parts then
    return nil
  end

  return math.floor(os.time({
    year = parts.year,
    month = parts.month,
    day = parts.day,
    hour = 12,
  }) / 86400)
end

local function date_from_filename(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.fs.basename(name):match("^(%d%d%d%d%-%d%d%-%d%d)%.md$")
end

function M.is_diary_file(buf)
  local name = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if name == "" then
    return false
  end

  local normalized_name = lower_path(name)

  local basename = vim.fs.basename(name)
  if not basename:match("^%d%d%d%d%-%d%d%-%d%d%.md$") then
    return false
  end

  for _, dir in ipairs(diary_dirs) do
    if vim.startswith(normalized_name, lower_path(dir)) then
      return true
    end
  end

  return false
end

function M.date_for_buffer(buf)
  return date_from_filename(buf) or os.date("%Y-%m-%d")
end

function M.dtl_for_date(date)
  local target = day_number(date)
  local baseline = day_number(base_date)
  if not target or not baseline then
    return base_dtl
  end

  return base_dtl - (target - baseline)
end

function M.header_lines(buf)
  local date = M.date_for_buffer(buf)
  local dtl = M.dtl_for_date(date)

  return {
    date,
    "",
    string.format("DTL: %d", dtl),
    "",
    "| S | M | Y |",
    "-------------",
    "|  |  |  |",
    "",
    "# YIL",
    "",
    "",
    "",
    "# TIL",
    "",
    "",
    "",
  }
end

function M.header_snippet(buf)
  local date = M.date_for_buffer(buf)
  local dtl = M.dtl_for_date(date)

  return table.concat({
    date,
    "",
    string.format("DTL: %d", dtl),
    "",
    "| S | M | Y |",
    "-------------",
    "| $1 | $2 | $3 |",
    "",
    "# YIL",
    "",
    "",
    "",
    "# TIL",
    "",
    "",
    "",
    "$0",
  }, "\n")
end

function M.insert_header(buf)
  if vim.bo[buf].modified or vim.api.nvim_buf_line_count(buf) > 1 then
    return
  end

  local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  if first_line ~= "" then
    return
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.header_lines(buf))

  if buf == vim.api.nvim_get_current_buf() then
    vim.api.nvim_win_set_cursor(0, { 7, 2 })
  end
end

function M.expand_header_trigger()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before_cursor = line:sub(1, col)
  local trigger = before_cursor:match("([%a][%w]*)$")
  if not trigger or not triggers[trigger] then
    return false
  end

  local start_col = col - #trigger
  vim.api.nvim_buf_set_text(0, row - 1, start_col, row - 1, col, { "" })
  vim.snippet.expand(M.header_snippet(0))
  return true
end

function M.expand_or_newline()
  if M.expand_header_trigger() then
    return ""
  end

  return "<C-j>"
end

function M.insert_header_at_cursor()
  vim.snippet.expand(M.header_snippet(0))
end

function M.setup_buffer(buf)
  if vim.b[buf].diary_header_ready then
    return
  end

  vim.b[buf].diary_header_ready = true

  vim.keymap.set("i", "<C-j>", function()
    return require("config.diary").expand_or_newline()
  end, {
    buffer = buf,
    expr = true,
    desc = "Expand diary header trigger",
  })

  vim.api.nvim_buf_create_user_command(buf, "DiaryHeader", function()
    require("config.diary").insert_header_at_cursor()
  end, {
    desc = "Insert the diary header snippet",
  })
end

return M
