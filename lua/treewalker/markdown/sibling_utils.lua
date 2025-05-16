local markdown_line_utils = require "treewalker.markdown.line_utils"
local section_utils = require "treewalker.markdown.section_utils"

local classify_line = markdown_line_utils.classify_line

local M = {}

--- List sibling headers of a given level and parent within a buffer range
---@param level integer
---@param parent_row integer|nil
---@param start_row integer
---@param end_row integer
---@return integer[]
function M.list_sibling_headers_of_level_in_bounds(level, parent_row, start_row, end_row)
  local result = {}
  for r = start_row, end_row do
    local info = classify_line(r)
    if info.type == "heading" and info.level == level then
      local this_p, _ = section_utils.find_parent_header(r, info.level)
      if this_p == parent_row then
        table.insert(result, r)
      end
    end
  end
  return result
end

return M
