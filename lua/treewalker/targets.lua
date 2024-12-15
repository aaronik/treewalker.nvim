local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"

local M = {}

---@return integer, string, integer
function M.current()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  return current_row, current_line, current_col
end

---@return TSNode | nil, integer | nil, string | nil
function M.out()
  local node = nodes.get_current()
  local target = strategies.get_first_ancestor_with_diff_scol(node)
  if not target then return end
  local row = target:range()
  row = row + 1
  local line = lines.get_line(row)
  return target, row, line
end

---@return TSNode | nil, integer | nil, string | nil
function M.inn()
  local current_row, current_line, current_col = M.current()

  --- Go down and in
  local candidate, candidate_row, candidate_line =
      strategies.get_down_and_in(current_row, current_col)

  return candidate, candidate_row, candidate_line
end

---@return TSNode | nil, integer | nil, string | nil
function M.up()
  local current_row, current_line, current_col = M.current()

  -- Get next target if we're on an empty line
  local candidate, candidate_row, candidate_line =
      strategies.get_prev_if_on_empty_line(current_row, current_line)

  if candidate_row and candidate_line and candidate then
    return candidate, candidate_row, candidate_line
  end

  --- Get next target at the same column
  candidate, candidate_row, candidate_line =
      strategies.get_neighbor_at_same_col("up", current_row, current_col)

  if candidate_row and candidate_line and candidate then
    return candidate, candidate_row, candidate_line
  end
end

---@return TSNode | nil, integer | nil, string | nil
function M.down()
  local current_row, current_line, current_col = M.current()

  -- Get next target if we're on an empty line
  local candidate, candidate_row, candidate_line =
      strategies.get_next_if_on_empty_line(current_row, current_line)

  if candidate_row and candidate_line and candidate then
    return candidate, candidate_row, candidate_line
  end

  --- Get next target, if one is found
  candidate, candidate_row, candidate_line =
      strategies.get_neighbor_at_same_col("down", current_row, current_col)

  if candidate_row and candidate_line and candidate then
    return candidate, candidate_row, candidate_line
  end
end

return M
