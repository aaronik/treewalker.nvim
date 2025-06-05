local selectors = require "treewalker.markdown.selectors"
local heading = require "treewalker.markdown.heading"
local nodes = require "treewalker.nodes"

local M = {}

----------------------------------------------------------------------
-- Core heading movement (up, down, in, out) for markdown navigation --
----------------------------------------------------------------------

---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_down(current_row)
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

-- From a header, we go to neighbor header.
-- From not a header, we find the nearest header at any level
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_up(current_row)
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

---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_in(current_row)
  if not heading.is_heading(current_row) then return nil, nil end

  -- Try treesitter-based approach first
  local target_node, target_row = selectors.get_next_inner_heading(current_row)
  if target_node and target_row then
    return target_node, target_row
  end

  -- Fallback: if no child found, stay on current heading
  return nodes.get_at_row(current_row), current_row
end

-- Move out: go to nearest parent heading above.
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.find_out(current_row)
  local current_level = heading.heading_level(current_row)

  if current_level then
    -- We're on a heading, use treesitter-based parent search
    local target_node, target_row = selectors.get_prev_outer_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    -- We're on text content, find the nearest heading above using treesitter
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end

  return nil, nil
end

return M
