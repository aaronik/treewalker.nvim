-- Target selection helpers for Treewalker movement and swap.

local classify = require('treewalker.classify')
local lines = require('treewalker.lines')
local nodes = require('treewalker.nodes')

local M = {}

-- Get visual column for node's starting position.
-- This matches lines.get_start_col() and avoids byte/visual column mismatches.
---@param node TSNode
---@return integer
local function get_visual_col(node)
  local node_srow = nodes.get_srow(node)
  local line = lines.get_line(node_srow)
  return line and lines.get_start_col(line) or nodes.get_scol(node)
end

---@param node TSNode
---@return boolean
local function has_augment_child(node)
  local iter = node:iter_children()
  local child = iter()

  while child do
    if classify.is_augment_target(child) then
      return true
    end

    child = iter()
  end

  return false
end

---@param current_node TSNode
---@param node TSNode
---@param col integer
---@param row integer
---@return boolean
local function has_same_indent_jump_ancestor(current_node, node, col, row)
  local parent = node:parent()
  local iter = parent

  while iter do
    local iter_row = nodes.get_srow(iter)
    local iter_line = lines.get_line(iter_row)

    if
      iter_row < row
      and iter_line
      and classify.is_highlight_target(iter)
      and not has_augment_child(iter)
      and lines.get_start_col(iter_line) == col
    then
      if iter == current_node then
        return parent ~= current_node
      end

      return true
    end

    iter = iter:parent()
  end

  return false
end

---@param dir "up" | "down"
---@param current_node TSNode
---@param srow integer
---@param scol integer
---@return TSNode | nil, integer | nil
local function find_neighbor_at_same_col(dir, current_node, srow, scol)
  local candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(srow, dir)

  while candidate and candidate_row and candidate_line do
    local candidate_col = lines.get_start_col(candidate_line)
    local strow = candidate:range()
    if
        classify.is_jump_target(candidate)
        and candidate_line ~= ""
        and candidate_col == scol
        and not has_same_indent_jump_ancestor(current_node, candidate, candidate_col, candidate_row)
        and candidate_row == strow + 1
    then
      break
    else
      candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(candidate_row, dir)
    end
  end

  if candidate and candidate_row then
    return candidate, candidate_row
  end
end

---@param srow integer
---@param scol integer
---@return TSNode | nil, integer | nil
local function find_down_and_in(srow, scol)
  local last_row = vim.api.nvim_buf_line_count(0)

  if last_row == srow then return end

  for candidate_row = srow + 1, last_row, 1 do
    local candidate_line = lines.get_line(candidate_row)
    if not candidate_line then goto continue end
    local candidate_col = lines.get_start_col(candidate_line)
    local candidate = nodes.get_at_row(candidate_row)
    local is_empty = candidate_line == ""

    if candidate_col == scol or not candidate then
      goto continue
    elseif candidate_col > scol and classify.is_jump_target(candidate) then
      return candidate, candidate_row
    elseif candidate_col < scol and not is_empty then
      break
    end

    ::continue::
  end

end

---@param node TSNode
---@return TSNode | nil
local function find_first_ancestor_with_diff_scol(node)
  local iter_ancestor = node:parent()
  while iter_ancestor do
    if classify.is_jump_target(iter_ancestor) and not nodes.have_same_scol(node, iter_ancestor) then
      return iter_ancestor
    end

    iter_ancestor = iter_ancestor:parent()
  end
end

-- Returns the outermost string node containing the cursor node.
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

---@param node TSNode
---@param _current_row integer | nil
---@return TSNode | nil, integer | nil
function M.find_out(node, _current_row)
  -- When starting in a comment, behave like the node below the comment.
  -- Note: For some reason, this isn't required locally (macos _or_ Makefile ubuntu,
  -- but does fail on CI. TODO figure out the differences)
  if classify.is_comment_node(node) then
    node = M.find_down(node, nodes.get_srow(node)) or node
  end

  local candidate = find_first_ancestor_with_diff_scol(node)
  if not candidate then return end
  local row = nodes.get_srow(candidate)
  return candidate, row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_in(current_node, current_row)
  local current_col = nodes.get_scol(current_node)
  local candidate, candidate_row = find_down_and_in(current_row, current_col)
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_up(current_node, current_row)
  local current_col = get_visual_col(current_node)
  local candidate, candidate_row = find_neighbor_at_same_col(
    "up",
    current_node,
    current_row,
    current_col
  )
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_down(current_node, current_row)
  local current_col = get_visual_col(current_node)
  local candidate, candidate_row = find_neighbor_at_same_col(
    "down",
    current_node,
    current_row,
    current_col
  )
  return candidate, candidate_row
end

return M
