local nodes = require "treewalker.nodes"
local strategies = require "treewalker.strategies"
local util = require "treewalker.util"
local lines = require "treewalker.lines"
local markdown_targets = require "treewalker.markdown.targets"

local M = {}

-- Gets a bunch of information about where the user currently is.
---@return integer, integer
local function current()
  local current_row = vim.fn.line(".")
  local current_node = nodes.get_current()
  local highest_coincident = nodes.get_highest_row_coincident(current_node)
  return current_row, nodes.get_scol(highest_coincident)
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

---Walk up to find the highest comment node in a comment tree
---@param node TSNode
---@return TSNode
local function get_highest_comment_node(node)
  local top_comment = node
  while top_comment:parent() and top_comment:parent():type():match("comment") do
    top_comment = top_comment:parent()
  end
  return top_comment
end

---Find a previous sibling that's a class or function declaration
---@param node TSNode
---@return TSNode | nil
local function find_declaration_sibling(node)
  local sibling = node:prev_sibling()
  while sibling do
    if nodes.is_jump_target(sibling) then
      if sibling:type():match("class") or sibling:type():match("function") then
        return sibling
      end
    end
    sibling = sibling:prev_sibling()
  end
  return nil
end

---Search nearby lines (within 10 rows) for a class declaration
---@param current_row integer
---@return TSNode | nil
local function search_nearby_for_class(current_row)
  for i = math.max(1, current_row - 10), math.min(vim.api.nvim_buf_line_count(0), current_row + 10) do
    local line = lines.get_line(i)
    if line and line:match("class%s") then
      local potential_node = nodes.get_at_row(i)
      if potential_node and potential_node:type():match("class") and nodes.is_jump_target(potential_node) then
        return potential_node
      end
    end
  end
  return nil
end

---@param node TSNode
---@return TSNode | nil, integer | nil
function M.out(node)
  if util.is_markdown_file() then
    return markdown_targets.out()
  end

  local candidate = strategies.get_first_ancestor_with_diff_scol(node)
  if not candidate then
    candidate = strategies.get_first_ancestor_jump_target(node)
  end

  -- If we're in a comment and the candidate is a body node, go to the declaration instead
  if node:type():match("comment") and candidate and candidate:type():match("body") then
    local declaration = candidate:parent()
    if declaration and nodes.is_jump_target(declaration) then
      candidate = declaration
    end
  end

  -- If we're in a comment and don't have a candidate, try to find related declaration
  if not candidate and node:type():match("comment") then
    local top_comment = get_highest_comment_node(node)

    -- Check if we're inside a body structure
    local parent = top_comment:parent()
    if parent and parent:type():match("body") then
      -- We're inside a body, go to the parent declaration
      candidate = parent:parent()
    elseif parent then
      -- Look for a previous sibling that's a declaration
      candidate = find_declaration_sibling(top_comment)
    end
  end

  -- Final fallback: if we still don't have a candidate and we're in/near a comment,
  -- search nearby lines for a class or function declaration
  if not candidate then
    local current_row = vim.fn.line('.')
    local current_line = lines.get_line(current_row)
    if current_line and (current_line:match("/%*") or current_line:match("%*") or current_line:match("%*/")) then
      candidate = search_nearby_for_class(current_row)
    end
  end

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
