local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"

local M = {}

-- Gets node at row start point
---@return integer, integer
local function current()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  assert(current_line, "cursor cannot be on invalid line number")
  local current_col = lines.get_start_col(current_line)
  return current_row, current_col
end

---@param node TSNode
---@return TSNode | nil, integer | nil
function M.out(node)
  local target = strategies.get_first_ancestor_with_diff_scol(node)
  if not target then return end
  local row = nodes.get_srow(target)
  return target, row
end

---@return TSNode | nil, integer | nil
function M.inn()
  local current_row, current_col = current()

  local candidate, candidate_row =
      strategies.get_down_and_in(current_row, current_col)

  return candidate, candidate_row
end

---@return TSNode | nil, integer | nil
function M.up()
  local current_row, current_col = current()

  -- Get next target if we're on an empty line
  local candidate, candidate_row =
      strategies.get_prev_if_on_empty_line(current_row)

  if candidate and candidate_row then
    return candidate, candidate_row
  end

  --- Get next target at the same column
  candidate, candidate_row = strategies.get_neighbor_at_same_col("up", current_row, current_col)

  if candidate and candidate_row then
    return candidate, candidate_row
  end
end

---@return TSNode | nil, integer | nil
function M.down()
  local current_row, current_col = current()

  -- Get next target if we're on an empty line
  local candidate, candidate_row =
      strategies.get_next_if_on_empty_line(current_row)

  if candidate and candidate_row then
    return candidate, candidate_row
  end

  --- Get next target, if one is found
  candidate, candidate_row = strategies.get_neighbor_at_same_col("down", current_row, current_col)

  if candidate and candidate_row then
    return candidate, candidate_row
  end
end

return M
