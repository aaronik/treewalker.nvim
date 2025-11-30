local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"
local util = require "treewalker.util"
local markdown_targets = require "treewalker.markdown.targets"

local M = {}

---@param node TSNode
---@return TSNode | nil, integer | nil
function M.out(node)
  if util.is_markdown_file() then
    return markdown_targets.out()
  end

  -- In case we're in a comment, we want to behave as though we were in the
  -- node below the comment
  -- Note: For some reason, this isn't required locally (macos _or_ Makefile ubuntu,
  -- but does fail on CI. TODO figure out the differences)
  if nodes.is_comment_node(node) then
    node = M.down(node, nodes.get_srow(node)) or node
  end

  local candidate = strategies.get_first_ancestor_with_diff_scol(node)
  if not candidate then return end
  local row = nodes.get_srow(candidate)
  return candidate, row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.inn(current_node, current_row)
  if util.is_markdown_file() then
    return markdown_targets.inn()
  end
  local current_col = nodes.get_scol(current_node)
  local candidate, candidate_row = strategies.get_down_and_in(current_row, current_col, nil, nil)
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.up(current_node, current_row)
  if util.is_markdown_file() then
    return markdown_targets.up()
  end
  local current_col = nodes.get_scol(current_node)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("up", current_row, current_col, nil, nil)
  return candidate, candidate_row
end

---@param current_node TSNode
---@param current_row number
---@return TSNode | nil, integer | nil
function M.down(current_node, current_row)
  if util.is_markdown_file() then
    return markdown_targets.down()
  end
  local current_col = nodes.get_scol(current_node)
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("down", current_row, current_col, nil, nil)
  return candidate, candidate_row
end

return M
