-- All strategies follow a similar pattern of taking the information they need,
-- and also any previous return values from other strategies. This allows for
-- easy chaining, so instead of the old, we can use the new:
-- Old:
--
-- local candidate, candidate_row =
--     strategies.get_prev_if_on_empty_line(current_row)
--
-- if candidate and candidate_row then
--   return candidate, candidate_row
-- end
--
-- candidate, candidate_row =
--   strategies.get_neighbor_at_same_col("up", current_row, current_col)
--
-- if candidate and candidate_row then
--   return candidate, candidate_row
-- end
--
--
-- New:
--
-- local candidate, candidate_row =
--    local candidate, row
--    candidate, row = strategies.get_neighbor_at_same_col("up", current_row, current_col, nil, nil)
--    candidate, row = strategies.get_prev_if_on_empty_line(current_row, candidate, row)
--    return candidate, row
--
-- Notice how the order is switched, so least desirable candidates come first,
-- and most desirable last.
--
-- Also note this is only for multiple return strategies, all strategies that return only
-- a single node won't use this technique, as the following works better, preserving all types:
-- node = strategies.whatever(node) or node

local lines = require("treewalker.lines")
local nodes = require("treewalker.nodes")

local M = {}

-- Gets the next target in the up/down directions
---@param dir "up" | "down"
---@param srow integer
---@param scol integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return  TSNode | nil, integer | nil
function M.get_neighbor_at_same_col(dir, srow, scol, prev_candidate, prev_row)
  local candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(srow, dir)

  while candidate and candidate_row and candidate_line do
    local candidate_col = lines.get_start_col(candidate_line)
    local strow = candidate:range()
    if
      nodes.is_jump_target(candidate) -- only node types we consider jump targets
      and candidate_line ~= "" -- no empty lines
      and candidate_col == scol -- stay at current indent level
      and candidate_row == strow + 1 -- top of block; no end's or else's etc.
    then
      break -- use most recent assignment below
    else
      candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(candidate_row, dir)
    end
  end

  if candidate and candidate_row then
    return candidate, candidate_row
  else
    return prev_candidate, prev_row
  end
end

-- Go down until there is a valid jump target to the right
---@param srow integer
---@param scol integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_down_and_in(srow, scol, prev_candidate, prev_row)
  local last_row = vim.api.nvim_buf_line_count(0)

  -- Can't go down if we're at the bottom
  if last_row == srow then
    return prev_candidate, prev_row
  end

  for candidate_row = srow + 1, last_row, 1 do
    local candidate_line = lines.get_line(candidate_row)
    if not candidate_line then
      goto continue
    end
    local candidate_col = lines.get_start_col(candidate_line)
    local candidate = nodes.get_at_row(candidate_row)
    local is_empty = candidate_line == ""

    if candidate_col == scol or not candidate then
      goto continue
    elseif candidate_col > scol and nodes.is_jump_target(candidate) then
      return candidate, candidate_row
    elseif candidate_col < scol and not is_empty then
      break
    end

    ::continue:: -- gross
  end

  return prev_candidate, prev_row
end

-- Special case for when starting on empty line. In that case, find the next
-- line with stuff on it, and go to that.
---@param srow integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_next_if_on_empty_line(srow, prev_candidate, prev_row)
  local start_line = lines.get_line(srow)
  if start_line ~= "" then
    return prev_candidate, prev_row
  end

  ---@type string | nil
  local current_line = start_line
  local max_row = vim.api.nvim_buf_line_count(0)
  local current_row = srow
  local current_node = nodes.get_at_row(current_row)

  while
    true and current_line == ""
    or current_node and not nodes.is_jump_target(current_node) and current_row <= max_row
  do
    current_row = current_row + 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row > max_row then
    return prev_candidate, prev_row
  end

  if current_node and current_row then
    return current_node, current_row
  else
    return prev_candidate, prev_row
  end
end

-- Special case for when starting on empty line. In that case, find the prev
-- line with stuff on it, and go to that.
---@param srow integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_prev_if_on_empty_line(srow, prev_candidate, prev_row)
  local start_line = lines.get_line(srow)
  if start_line ~= "" then
    return prev_candidate, prev_row
  end

  ---@type string | nil
  local current_line = start_line
  local current_row = srow
  local current_node = nodes.get_at_row(current_row)

  while true and current_line == "" or current_node and not nodes.is_jump_target(current_node) and current_row >= 0 do
    current_row = current_row - 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row < 0 then
    return prev_candidate, prev_row
  end

  if current_node and current_row then
    return current_node, current_row
  else
    return prev_candidate, prev_row
  end
end

---Get the nearest ancestral node _which has different coordinates than the passed in node_
---@param node TSNode
---@return TSNode | nil
function M.get_first_ancestor_with_diff_scol(node)
  local iter_ancestor = node:parent()
  while iter_ancestor do
    if true and nodes.is_jump_target(iter_ancestor) and not nodes.have_same_scol(node, iter_ancestor) then
      return iter_ancestor
    end

    iter_ancestor = iter_ancestor:parent()
  end
end

-- Use this to get the whole string from inside of a string
-- returns nils if the passed in node is not a string node
---@param node TSNode
---@return TSNode | nil
function M.get_highest_string_node(node)
  ---@type TSNode | nil
  local highest = nil
  ---@type TSNode | nil
  local iter = node

  while iter do
    if string.match(iter:type(), "string") then
      highest = iter
    end
    iter = iter:parent()
  end

  return highest
end

return M
