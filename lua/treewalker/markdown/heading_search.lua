-- Utility to find the next/prev heading row given a matcher.
local nodes = require "treewalker.nodes"

local M = {}

--- Find the next or previous heading matching a condition.
---@param start_row integer: where to start search
---@param opts table: {dir=1|-1, matcher=function(check_row):bool}
---@return TSNode|nil, integer|nil
function M.find_heading(start_row, opts)
  local dir = opts.dir
  local matcher = opts.matcher or function(_) return true end
  local max_row = vim.api.nvim_buf_line_count(0)
  local row = start_row + dir
  while row >= 1 and row <= max_row do
    if matcher(row) then
      local node = nodes.get_at_row(row)
      return node, row
    end
    row = row + dir
  end
  return nil, nil
end

return M
