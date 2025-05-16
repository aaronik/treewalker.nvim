local nodes = require "treewalker.nodes"
local line_utils = require "treewalker.markdown.line_utils"
local selectors = require "treewalker.markdown.selectors"
local levels = require "treewalker.markdown.levels"

local classify_line = line_utils.classify_line

return function(current_row)
  if current_row == 1 and levels.is_heading(current_row) and levels.heading_level(current_row) == 1 then
    local next_row = current_row + 1
    local next_info = classify_line(next_row)
    if next_info.type == "underline" then
      local node = nodes.get_at_row(next_row)
      return node, next_row
    end
  end
  if levels.is_heading(current_row) then
    local target_node, target_row = selectors.get_next_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    else
      return nodes.get_at_row(current_row), current_row
    end
  else
    local target_node, target_row = selectors.get_nearest_next_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
  return nil, nil
end
