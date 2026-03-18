local selectors = require "treewalker.markdown.selectors"
local heading = require "treewalker.markdown.heading"
local nodes = require "treewalker.nodes"

local M = {}

---@param _current_node TSNode
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_down(_current_node, current_row)
  if heading.is_heading(current_row) then
    local target_node, target_row = selectors.get_next_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    local target_node, target_row = selectors.get_nearest_next_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
end

---@param _current_node TSNode
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_up(_current_node, current_row)
  if heading.is_heading(current_row) then
    local target_node, target_row = selectors.get_prev_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
end

---@param _current_node TSNode
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_in(_current_node, current_row)
  if not heading.is_heading(current_row) then return nil, nil end

  local target_node, target_row = selectors.get_next_inner_heading(current_row)
  if target_node and target_row then
    return target_node, target_row
  end

  return nodes.get_at_row(current_row), current_row
end

---@param _current_node TSNode
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_out(_current_node, current_row)
  local current_level = heading.heading_level(current_row)

  if current_level then
    local target_node, target_row = selectors.get_prev_outer_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end

  return nil, nil
end

return M
