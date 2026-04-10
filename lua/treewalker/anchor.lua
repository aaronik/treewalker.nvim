local classify = require "treewalker.classify"
local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"

local M = {}

---@class TreewalkerAnchor
---@field node TSNode
---@field row integer
---@field start_row integer
---@field end_row integer
---@field col integer
---@field indent integer
---@field line string
---@field attached_rows [integer, integer]
---@field augment_length integer

---@param node TSNode
---@return TSNode
local function normalize_node(node)
  local anchor = node

  ---@type TSNode | nil
  local iter = node

  while iter and nodes.have_same_srow(anchor, iter) do
    if classify.is_highlight_target(iter) then
      anchor = iter
    end
    iter = iter:parent()
  end

  return anchor
end

---@param row integer
---@param col integer
---@return TSNode | nil
local function normalized_node_at(row, col)
  local node = nodes.get_at(row, col)

  if not node then return nil end

  return normalize_node(node)
end

---@param row integer
---@return TSNode | nil
local function node_at_row(row)
  local line = lines.get_line(row)
  if not line then return nil end

  local col = lines.get_start_col(line)
  local node = normalized_node_at(row, col)
  local next_node = nil ---@type TSNode | nil

  if col <= #line then
    next_node = normalized_node_at(row, col + 1)
  end

  if node and classify.is_highlight_target(node) and nodes.get_srow(node) == row then
    return node
  end

  if next_node and classify.is_highlight_target(next_node) and nodes.get_srow(next_node) == row then
    return next_node
  end

  if node and classify.is_highlight_target(node) then
    return node
  end

  if next_node and classify.is_highlight_target(next_node) then
    return next_node
  end

  return next_node or node
end

---@param node TSNode
---@return TSNode[]
local function get_augments(node)
  local row = nodes.get_srow(node)

  ---@type TSNode[]
  local augments = {}

  while row > 1 do
    local candidate = node_at_row(row - 1)
    if not candidate or not classify.is_augment_target(candidate) then
      break
    end

    table.insert(augments, candidate)
    row = nodes.get_srow(candidate)
  end

  return augments
end

---@param anchor_node TSNode
---@param row integer | nil
---@return TreewalkerAnchor
local function build_anchor(anchor_node, row)
  local start_row = nodes.get_srow(anchor_node)
  local anchor_row = row or start_row
  local line = lines.get_line(anchor_row)
  if not line then
    error("Treewalker: missing line for anchor")
  end

  local augments = get_augments(anchor_node)

  ---@type [integer, integer]
  local attached_rows = nodes.whole_range({ anchor_node, unpack(augments) })

  local augment_length = 0
  if #augments > 0 then
    ---@type [integer, integer]
    local augment_rows = nodes.whole_range(augments)
    augment_length = start_row - augment_rows[1] - 1
  end

  local indent_row = anchor_row
  if line == "" or not classify.is_jump_target(anchor_node) then
    indent_row = start_row
  end

  local indent_line = lines.get_line(indent_row)
  if not indent_line then
    error("Treewalker: missing indent line for anchor")
  end

  return {
    node = anchor_node,
    row = anchor_row,
    start_row = start_row,
    end_row = nodes.get_erow(anchor_node),
    col = nodes.get_scol(anchor_node),
    indent = lines.get_start_col(indent_line),
    line = line,
    attached_rows = attached_rows,
    augment_length = augment_length,
  }
end

---@param node TSNode
---@param row integer | nil
---@return TreewalkerAnchor
function M.from_node(node, row)
  return build_anchor(normalize_node(node), row)
end

---@param row integer
---@return TreewalkerAnchor | nil
function M.at_row(row)
  local node = node_at_row(row)
  if not node then return nil end

  local anchor_row = row
  if classify.is_augment_target(node) then
    anchor_row = nodes.get_srow(node)
  end

  return M.from_node(node, anchor_row)
end

---@return TreewalkerAnchor
function M.current()
  local row = vim.fn.line('.')
  local current_anchor = M.at_row(row)
  if not current_anchor then
    error("Treewalker: Treesitter node not found under cursor. Missing parser?")
  end
  return current_anchor
end

---@param node TSNode
---@return TSNode
local function normalize_lateral_node(node)
  local lateral = M.get_highest_string_node(node) or node
  local iter = lateral:parent()

  while iter and nodes.have_same_srow(lateral, iter) and nodes.have_same_scol(lateral, iter) do
    if classify.is_highlight_target(iter) then
      lateral = iter
    end
    iter = iter:parent()
  end

  return lateral
end

---@return TSNode
function M.current_lateral_node()
  local current = vim.treesitter.get_node({ ignore_injections = false })
  if not current then
    error("Treewalker: Treesitter node not found under cursor. Missing parser?")
  end
  return normalize_lateral_node(current)
end

-- Convenience for give me back next sibling of a potentially nil node
---@param node TSNode | nil
---@return TSNode | nil
function M.next_sibling(node)
  if not node then return nil end
  return node:next_named_sibling()
end

-- Convenience for give me back prev sibling of a potentially nil node
---@param node TSNode | nil
---@return TSNode | nil
function M.prev_sibling(node)
  if not node then return nil end
  return node:prev_named_sibling()
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

---@param current TreewalkerAnchor
---@param candidate TreewalkerAnchor
---@return boolean
local function has_same_indent_jump_ancestor(current, candidate)
  ---@type TSNode | nil
  local parent = candidate.node:parent()

  ---@type TSNode | nil
  local iter = parent

  while iter do
    local iter_row = nodes.get_srow(iter)
    local iter_line = lines.get_line(iter_row)

    if
      iter_row < candidate.row
      and iter_line
      and classify.is_highlight_target(iter)
      and not has_augment_child(iter)
      and lines.get_start_col(iter_line) == candidate.indent
    then
      if iter == current.node then
        return parent ~= current.node
      end

      return true
    end

    iter = iter:parent()
  end

  return false
end

---@param direction "up" | "down"
---@param current TreewalkerAnchor
---@return TreewalkerAnchor | nil
function M.find_neighbor(direction, current)
  local step = direction == "up" and -1 or 1
  local max_row = vim.api.nvim_buf_line_count(0)
  local row = current.row + step

  while row >= 1 and row <= max_row do
    local candidate = M.at_row(row)

    if
      candidate
      and candidate.start_row == row
      and candidate.line ~= ""
      and candidate.indent == current.indent
      and classify.is_jump_target(candidate.node)
      and not has_same_indent_jump_ancestor(current, candidate)
    then
      return candidate
    end

    row = row + step
  end
end

---@param current TreewalkerAnchor
---@return TreewalkerAnchor | nil
function M.find_up(current)
  return M.find_neighbor("up", current)
end

---@param current TreewalkerAnchor
---@return TreewalkerAnchor | nil
function M.find_down(current)
  return M.find_neighbor("down", current)
end

---@param current TreewalkerAnchor
---@return TreewalkerAnchor | nil
function M.find_in(current)
  local max_row = vim.api.nvim_buf_line_count(0)

  for row = current.row + 1, max_row, 1 do
    local line = lines.get_line(row)
    if line then
      local indent = lines.get_start_col(line)
      local candidate = M.at_row(row)

      if indent > current.indent and candidate and classify.is_jump_target(candidate.node) then
        return candidate
      end

      if indent < current.indent and line ~= "" then
        break
      end
    end
  end
end

---@param current TreewalkerAnchor
---@return TreewalkerAnchor | nil
function M.find_out(current)
  if classify.is_comment_node(current.node) then
    current = M.find_down(current) or current
  end

  local iter = current.node:parent()
  while iter do
    if classify.is_jump_target(iter) and not nodes.have_same_scol(current.node, iter) then
      return build_anchor(iter, nodes.get_srow(iter))
    end
    iter = iter:parent()
  end
end

---@param node TSNode
---@return TSNode | nil
function M.get_highest_string_node(node)
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
