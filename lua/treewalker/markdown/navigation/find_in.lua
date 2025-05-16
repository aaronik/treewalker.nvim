local nodes = require "treewalker.nodes"
local line_utils = require "treewalker.markdown.line_utils"
local selectors = require "treewalker.markdown.selectors"

local classify_line = line_utils.classify_line

return function(current_row)
  local info = classify_line(current_row)
  if info.type == "heading" then
    local target_node, target_row = selectors.get_next_inner_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    else
      return nodes.get_at_row(current_row), current_row
    end
  else
    return nodes.get_at_row(current_row), current_row
  end
end
