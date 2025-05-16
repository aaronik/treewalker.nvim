local nodes = require "treewalker.nodes"
local selectors = require "treewalker.markdown.selectors"
local levels = require "treewalker.markdown.levels"


return function(current_row)
  if not levels.is_heading(current_row) then
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  elseif levels.is_heading(current_row) then
    if current_row == 1 then
      return nil, nil
    end
    local target_node, target_row = selectors.get_prev_outer_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    elseif levels.heading_level(current_row) > 1 then
      for row = 1, current_row - 1 do
        if levels.heading_level(row) == 1 then
          local h1_node = nodes.get_at_row(row)
          return h1_node, row
        end
      end
    end
  end
  return nil, nil
end
