-- Utility functions
local M = {}

-- remove program code from lua cache, reload
M.RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

-- modified 'require'; use to flush entire program from top level for plugin development.
M.R = function(name)
  M.RELOAD(name)
  return require(name)
end

-- print tables contents
M.P = function(v)
  print(vim.inspect(v))
  return v
end

-- Log to the file debug.log in the plugin's data dir. File can be watched for easier debugging.
M.log = function(...)
  local args = { ... }

  -- Canonical log dir
  local data_path = vim.fn.stdpath("data") .. "/treewalker"

  -- If no dir on fs, make it
  if vim.fn.isdirectory(data_path) == 0 then
    vim.fn.mkdir(data_path, "p")
  end

  local log_file = io.open(data_path .. "/debug.log", "a")

  -- Guard against no log file by making one
  if not log_file then
    log_file = io.open(data_path .. "/debug.log", "w+")
  end

  -- Swallow further errors
  -- This is a utility for development, it should never cause issues
  -- during real use.
  if not log_file then return end

  -- Write each arg to disk
  for _, arg in ipairs(args) do
    if type(arg) == "table" then
      arg = vim.inspect(arg)
    end

    log_file:write(tostring(arg) .. "\n")
  end

  log_file:flush() -- Ensure the output is written immediately
  log_file:close()
end

M.guid = function()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

---reverse an array table
---@param t table
M.reverse = function (t)
  local reversed = {}
  for _, el in ipairs(t) do
    table.insert(reversed, 1, el)
  end
  return reversed
end

--- Returns true if current buffer's filetype is markdown
---@return boolean
M.is_markdown_file = function()
  local ft = vim.bo and vim.bo.ft or (vim.api and vim.api.nvim_buf_get_option and vim.api.nvim_buf_get_option(0, 'filetype')) or ''
  return ft == "markdown" or ft == "md"
end

---Returns true if the given row (or the current row) is the start of a markdown header
---@param row integer|nil
---@return boolean
function M.is_on_markdown_header(row)
  if not M.is_markdown_file() then return false end
  row = row or vim.fn.line(".")
  local level = require("treewalker.strategies").get_markdown_heading_level(row)
  return level ~= nil
end

-- Returns normalized (row, heading_level) for markdown, adjusting for underline-style headers.
-- If not header: returns (row, nil)
---@param row integer
---@return integer, integer|nil
function M.normalize_markdown_header_row(row)
  if not M.is_markdown_file() then return row, nil end
  local strategies = require 'treewalker.strategies'
  local level, is_underline = strategies.get_markdown_heading_level(row)
  if is_underline and row > 1 then
    row = row - 1
    level, _ = strategies.get_markdown_heading_level(row)
  end
  return row, level
end

--- Given a TSNode (preferred) or nil, returns (row, col). If nil, uses start of line col if as_line_start is true.
---@param node TSNode|nil
---@param as_line_start boolean|nil
---@return integer row, integer col
function M.resolve_row_col(node, as_line_start)
  local nodes = require 'treewalker.nodes'
  local lines = require 'treewalker.lines'
  if node and node.range then
    return nodes.get_srow(node), nodes.get_scol(node)
  else
    local row = vim.fn.line('.')
    local col
    if as_line_start then
      local line = lines.get_line(row)
      col = lines.get_start_col(line)
    else
      col = vim.fn.col('.')
    end
    return row, col
  end
end

return M
