local selectors = require "treewalker.markdown.selectors"
local levels = require "treewalker.markdown.levels"


return function(current_row)
  if not levels.is_heading(current_row) then
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    if current_row == 1 then
      return nil, nil
    end
    local target_node, target_row = selectors.get_prev_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
  return nil, nil
end
