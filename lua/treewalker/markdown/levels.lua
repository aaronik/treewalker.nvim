local line_utils = require "treewalker.markdown.line_utils"

local M = {}

--- Gets heading info at a given row, or nil if it's not a heading.
---@param row integer
---@return table|nil
local function heading_info(row)
  local info = line_utils.classify_line(row)
  if info.type == "heading" then
    return info
  end
  return nil
end

--- Checks if two rows are headings at the same level (siblings).
function M.is_sibling(row1, row2)
  local h1, h2 = heading_info(row1), heading_info(row2)
  return h1 and h2 and h1.level == h2.level
end

--- Returns true if row2 is a parent heading (one level higher) of row1.
function M.is_parent(row1, row2)
  local h1, h2 = heading_info(row1), heading_info(row2)
  return h1 and h2 and h2.level == h1.level - 1
end

--- Returns true if row2 is a child heading of row1 (one level deeper).
function M.is_child(row1, row2)
  local h1, h2 = heading_info(row1), heading_info(row2)
  return h1 and h2 and h2.level == h1.level + 1
end

--- Returns heading level number at row, or nil if not a heading.
function M.heading_level(row)
  local info = heading_info(row)
  return info and info.level or nil
end

--- Returns info table ({type, level}) for a heading at row, or nil if not a heading.
function M.heading_info(row)
  return heading_info(row)
end

--- Returns true if row is a heading (any level)
function M.is_heading(row)
  local info = line_utils.classify_line(row)
  return info.type == "heading"
end

return M
