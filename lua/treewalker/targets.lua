local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"
local lines = require "treewalker.lines"

local M = {}

-- Get visual column for node's starting position
-- This matches lines.get_start_col() used in strategies.lua
-- Needed because get_scol() returns byte column, but strategies uses visual column
local function get_visual_col(node)
  local node_srow = nodes.get_srow(node)
  local line = lines.get_line(node_srow)
  return line and lines.get_start_col(line) or nodes.get_scol(node)
end

---@param node TSNode
---@param _current_row integer | nil
---@return TSNode | nil, integer | nil
function M.find_out(node, _current_row)
  -- In case we're in a comment, we want to behave as though we were in the
  -- node below the comment
  -- Note: For some reason, this isn't required locally (macos _or_ Makefile ubuntu,
  -- but does fail on CI. TODO figure out the differences)
  if nodes.is_comment_node(node) then
    node = M.find_down(node, nodes.get_srow(node)) or node
  end

  local candidate = strategies.get_first_ancestor_with_diff_scol(node)
  if not candidate then return end
  local row = nodes.get_srow(candidate)
  return candidate, row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_in(current_node, current_row)
  local current_col = nodes.get_scol(current_node)
  local candidate, candidate_row = strategies.get_down_and_in(current_row, current_col, nil, nil)
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_up(current_node, current_row)
  local current_col = get_visual_col(current_node)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col(
    "up",
    current_node,
    current_row,
    current_col,
    nil,
    nil
  )
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.find_down(current_node, current_row)
  local current_col = get_visual_col(current_node)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col(
    "down",
    current_node,
    current_row,
    current_col,
    nil,
    nil
  )
  return candidate, candidate_row
end

return M
