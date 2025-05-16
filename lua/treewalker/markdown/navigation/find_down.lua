local nodes = require "treewalker.nodes"
local selectors = require "treewalker.markdown.selectors"
local levels = require "treewalker.markdown.levels"

return function(current_row)
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
