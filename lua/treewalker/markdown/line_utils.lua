-- luacheck: globals vim
local util = require "treewalker.util"
local lines = require "treewalker.lines"
local M = {}

--- Classifies a markdown line based on what kind of line it is.
-- { type = "heading", level = N }
-- { type = "underline", underline_level = N } (N=1 for =, N=2 for -)
-- { type = "none" }
---@param row integer
---@return table
function M.classify_line(row)
  if not row then return { type = "none" } end
  if not util.is_markdown_file() then return { type = "none" } end
  local line = lines.get_line(row)
  if not line then return { type = "none" } end
  local level_match = line:match("^(#+)%s")
  if level_match then
    return { type = "heading", level = #level_match }
  end
  if line:match("^=+%s*$") then
    return { type = "underline", underline_level = 1 }
  end
  if line:match("^-+%s*$") then
    return { type = "underline", underline_level = 2 }
  end
  if row < vim.api.nvim_buf_line_count(0) then
    local next_line = lines.get_line(row + 1)
    if line and line:match("^%S") and next_line then
      if next_line:match("^=+%s*$") then
        return { type = "heading", level = 1 }
      elseif next_line:match("^-+%s*$") then
        return { type = "heading", level = 2 }
      end
    end
  end
  return { type = "none" }
end

--- Normalize a line to return the row and info of the canonical heading at or above, handling underline-style cases.
---@param row integer
---@return integer|nil, table
function M.normalize_markdown_heading_row(row)
  local info = M.classify_line(row)
  if info.type == "underline" and row > 1 then
    row = row - 1
    info = M.classify_line(row)
  end
  return row, info
end

return M
