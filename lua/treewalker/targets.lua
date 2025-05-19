local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"
local util = require "treewalker.util"
local markdown_targets = require "treewalker.markdown.targets"

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

---Get the highest coincident; helper
---@param node TSNode | nil
---@return TSNode | nil
local function coincident(node)
  if node then
    return nodes.get_highest_coincident(node)
  else
    return node -- aka nil
  end
end

---@param node TSNode
---@return TSNode | nil, integer | nil
function M.out(node)
  if util.is_markdown_file() then
    return markdown_targets.out()
  end
  local candidate = strategies.get_first_ancestor_with_diff_scol(node)
  candidate = coincident(candidate)
  if not candidate then return end
  local row = nodes.get_srow(candidate)
  return candidate, row
end

---@return TSNode | nil, integer | nil
function M.inn()
  if util.is_markdown_file() then
    return markdown_targets.inn()
  end
  local current_row_, current_col = current()
  local candidate, candidate_row = strategies.get_down_and_in(current_row_, current_col, nil, nil)
  candidate = coincident(candidate)
  return candidate, candidate_row
end

---@return TSNode | nil, integer | nil
function M.up()
  if util.is_markdown_file() then
    return markdown_targets.up()
  end
  local current_row_, current_col = current()
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("up", current_row_, current_col, nil, nil)
  candidate, candidate_row = strategies.get_prev_if_on_empty_line(current_row_, candidate, candidate_row)
  candidate = coincident(candidate)
  return candidate, candidate_row
end

---@return TSNode | nil, integer | nil
function M.down()
  if util.is_markdown_file() then
    return markdown_targets.down()
  end
  local current_row_, current_col = current()
  local candidate, candidate_row = strategies.get_neighbor_at_same_col("down", current_row_, current_col, nil, nil)
  candidate, candidate_row = strategies.get_next_if_on_empty_line(current_row_, candidate, candidate_row)
  candidate = coincident(candidate)
  return candidate, candidate_row
end

return M
