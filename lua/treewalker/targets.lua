local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"
local util = require "treewalker.util"

local M = {}

-- Gets all directional logic out of the way
---@param direction 'out'|'inn'|'up'|'down'
---@param node TSNode|nil
---@return TSNode|nil, integer|nil
function M.get_direction_target(direction, node)
  if util.is_markdown_file() then
    return strategies.markdown_direction_target(direction, node)
  end
  if direction == 'out' then
    return M._out(node)
  elseif direction == 'inn' then
    return M._inn(node)
  elseif direction == 'up' then
    return M._up(node)
  elseif direction == 'down' then
    return M._down(node)
  else
    error("Unknown direction: " .. tostring(direction))
  end
end

-- Private: language-agnostic logic moved here; only called via router above
---@param node TSNode|nil
---@return TSNode|nil, integer|nil
function M._out(node)
  local candidate = strategies.get_first_ancestor_with_diff_scol(node)
  if candidate then
    candidate = nodes.get_highest_coincident(candidate)
  end
  if not candidate then return end
  local row = nodes.get_srow(candidate)
  return candidate, row
end

---@param node TSNode|nil
---@return TSNode|nil, integer|nil
function M._inn(node)
  local row, col = util.resolve_row_col(node, true)
  local candidate, candidate_row = strategies.get_down_and_in(row, col, nil, nil)
  if candidate then
    candidate = nodes.get_highest_coincident(candidate)
  end
  return candidate, candidate_row
end

---@param node TSNode|nil
---@return TSNode|nil, integer|nil
function M._up(node)
  local row, col = util.resolve_row_col(node, true)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("up", row, col, nil, nil)
  candidate, candidate_row = strategies.get_prev_if_on_empty_line(row, candidate, candidate_row)
  if candidate then
    candidate = nodes.get_highest_coincident(candidate)
  end
  return candidate, candidate_row
end

---@param node TSNode|nil
---@return TSNode|nil, integer|nil
function M._down(node)
  local row, col = util.resolve_row_col(node, true)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("down", row, col, nil, nil)
  candidate, candidate_row = strategies.get_next_if_on_empty_line(row, candidate, candidate_row)
  if candidate then
    candidate = nodes.get_highest_coincident(candidate)
  end
  return candidate, candidate_row
end

return M
