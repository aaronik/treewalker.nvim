local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"

local M = {}

-- Gets a bunch of information about where the user currently is.
-- I don't really like this here, I wish everything ran on nodes.
-- But the node information is often wrong, like the current node
-- could come back as a bigger containing scope, and the behavior
-- would be unintuitive.
---@return integer, integer
local function current()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  assert(current_line, "Treewalker: cursor is on invalid line number")
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
  local candidate, candidate_row = strategies.get_down_and_in(current_row, current_col, nil, nil)
  return candidate, candidate_row
end

---@return TSNode | nil, integer | nil
function M.up()
  local current_row, current_col = current()
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("up", current_row, current_col, nil, nil)
  candidate, candidate_row = strategies.get_prev_if_on_empty_line(current_row, candidate, candidate_row)
  return candidate, candidate_row
end

---@return TSNode | nil, integer | nil
function M.down()
  local current_row, current_col = current()
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("down", current_row, current_col, nil, nil)
  candidate, candidate_row = strategies.get_next_if_on_empty_line(current_row, candidate, candidate_row)
  return candidate, candidate_row
end

return M
