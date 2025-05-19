local heading = require "treewalker.markdown.heading"

local M = {}

---@param row integer
---@return integer | nil, integer | nil, integer | nil
function M.get_markdown_section_bounds(row)
  -- Use new heading.get_section_bounds which is more authoritative.
  return heading.get_section_bounds(row)
end

function M.find_parent_header(row, level)
  return heading.find_parent_header(row, level)
end

function M.get_parent_section_bounds(row, level)
  return heading.get_parent_section_bounds(row, level)
end

return M
