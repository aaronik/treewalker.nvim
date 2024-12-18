local lines = require('treewalker.lines')
local nodes = require('treewalker.nodes')

---@alias Dir "up" | "down"

-- Take row, give next row / node with same indentation
---@param current_row integer
---@param dir Dir
---@return TSNode | nil, integer | nil, string | nil
local function get_node_from_neighboring_line(current_row, dir)
  local candidate_row
  if dir == "up" then
    candidate_row = current_row - 1
  else
    candidate_row = current_row + 1
  end
  local max_row = vim.api.nvim_buf_line_count(0)
  if candidate_row > max_row or candidate_row <= 0 then return end
  local candidate_line = lines.get_line(candidate_row)
  local candidate_col = lines.get_start_col(candidate_line)
  local candidate = nodes.get_at_rowcol(candidate_row, candidate_col)
  return candidate, candidate_row, candidate_line
end

local M = {}

-- Gets the next target in the up/down directions
---@param dir Dir
---@param starting_row integer
---@param starting_col integer
---@return TSNode | nil, integer | nil, string | nil
function M.get_neighbor_at_same_col(dir, starting_row, starting_col)
  local candidate, candidate_row, candidate_line = get_node_from_neighboring_line(starting_row, dir)

  while candidate_row and candidate_line and candidate do
    local candidate_col = lines.get_start_col(candidate_line)
    local srow = candidate:range()
    if
        nodes.is_jump_target(candidate)   -- only node types we consider jump targets
        and candidate_line ~= ""          -- no empty lines
        and candidate_col == starting_col -- stay at current indent level
        and candidate_row == srow + 1     -- top of block; no end's or else's etc.
    then
      break                               -- use most recent assignment below
    else
      candidate, candidate_row, candidate_line = get_node_from_neighboring_line(candidate_row, dir)
    end
  end

  return candidate, candidate_row, candidate_line
end

-- Go down until there is a valid jump target to the right
---@param starting_row integer
---@param starting_col integer
---@return TSNode | nil, integer | nil, string | nil
function M.get_down_and_in(starting_row, starting_col)
  local last_row = vim.api.nvim_buf_line_count(0)

  if last_row == starting_row then return end

  for candidate_row = starting_row + 1, last_row, 1 do
    local candidate_line = lines.get_line(candidate_row)
    local candidate_col = lines.get_start_col(candidate_line)
    local candidate_node = nodes.get_at_row(candidate_row)
    local is_empty = candidate_line == ""

    if candidate_col == starting_col or not candidate_node then
      goto continue
    elseif candidate_col > starting_col and nodes.is_jump_target(candidate_node) then
      return candidate_node, candidate_row, candidate_line
    elseif candidate_col < starting_col and not is_empty then
      break
    end

    ::continue:: -- gross
  end
end

---Get the nearest ancestral node _which has different coordinates than the passed in node_
---@param node TSNode
---@return TSNode | nil
function M.get_first_ancestor_with_diff_scol(node)
  local iter_ancestor = node:parent()
  while iter_ancestor do
    if
        true
        and nodes.is_jump_target(iter_ancestor)
        and not nodes.have_same_scol(node, iter_ancestor)
    then
      return iter_ancestor
    end

    iter_ancestor = iter_ancestor:parent()
  end
end

-- Special case for when starting on empty line. In that case, find the next
-- line with stuff on it, and go to that.
---@param start_row integer
---@param start_line string
---@return TSNode | nil, integer | nil, string | nil
function M.get_next_if_on_empty_line(start_row, start_line)
  if start_line ~= "" then return end

  local max_row = vim.api.nvim_buf_line_count(0)
  local current_row = start_row
  local current_line = start_line
  local current_node = nodes.get_at_row(current_row)

  while
    true
    and current_line == ""
    or current_node and not nodes.is_jump_target(current_node)
    and current_row <= max_row
  do
    current_row = current_row + 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row > max_row then return end

  return current_node, current_row, current_line
end

-- Special case for when starting on empty line. In that case, find the prev
-- line with stuff on it, and go to that.
---@param start_row integer
---@param start_line string
---@return TSNode | nil, integer | nil, string | nil
function M.get_prev_if_on_empty_line(start_row, start_line)
  if start_line ~= "" then return end

  local current_row = start_row
  local current_line = start_line
  local current_node = nodes.get_at_row(current_row)

  while
    true
    and current_line == ""
    or current_node and not nodes.is_jump_target(current_node)
    and current_row >= 0
  do
    current_row = current_row - 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row < 0 then return end

  return current_node, current_row, current_line
end

return M
