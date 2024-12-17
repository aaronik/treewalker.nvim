local util = require "treewalker.util"
local lines = require "treewalker.lines"

-- These are regexes but just happen to be real simple so far
local TARGET_BLACKLIST_TYPE_MATCHERS = {
  "comment",
  "block"
}

local HIGHLIGHT_BLACKLIST_TYPE_MATCHERS = {
  "body",
  "block",
}


local M = {}

---@param node TSNode
---@param matchers string[]
---@return boolean
local function is_matched_in(node, matchers)
  for _, matcher in ipairs(matchers) do
    if node:type():match(matcher) then
      return true
    end
  end
  return false
end

---@param node TSNode
---@return boolean
local function is_root_node(node)
  return node:parent() == nil
end

---@param node TSNode
---@return boolean
function M.is_jump_target(node)
  return
      true
      and not is_matched_in(node, TARGET_BLACKLIST_TYPE_MATCHERS)
      and not is_root_node(node)
end

---@param node TSNode
---@return boolean
function M.is_highlight_target(node)
  return
      true
      and not is_matched_in(node, HIGHLIGHT_BLACKLIST_TYPE_MATCHERS)
      and not is_root_node(node)
end

---Do the nodes have the same starting point
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.have_same_start(node1, node2)
  local srow1, scol1 = node1:range()
  local srow2, scol2 = node2:range()
  return
      srow1 == srow2 and
      scol1 == scol2
end

---Do the nodes have the same starting row
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.have_same_row(node1, node2)
  return M.get_row(node1) == M.get_row(node2)
end

---Do the nodes have the same level of indentation
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.have_same_scol(node1, node2)
  local _, scol1 = node1:range()
  local _, scol2 = node2:range()
  return scol1 == scol2
end

---Do the nodes have the same starting line
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.on_same_line(node1, node2)
  local srow1 = node1:start()
  local srow2 = node2:start()
  return srow1 == srow2
end

---helper to get all the children from a node
---@param node TSNode
---@return TSNode[]
function M.get_children(node)
  local children = {}
  local iter = node:iter_children()
  local child = iter()
  while child do
    table.insert(children, child)
    child = iter()
  end
  return children
end

--- Get all descendants of a given TSNode
---@param node TSNode
---@return TSNode[]
function M.get_descendants(node)
  local descendants = {}

  -- Helper function to recursively collect descendants
  local function collect_descendants(current_node)
    local child_count = current_node:child_count()
    for i = 0, child_count - 1 do
      local child = current_node:child(i)
      table.insert(descendants, child)
      -- Recursively collect descendants of the child
      collect_descendants(child)
    end
  end

  -- Start the recursive collection with the given node
  collect_descendants(node)

  return descendants
end

-- Get farthest ancestor (or self) at the same starting row
---@param node TSNode
---@return TSNode
function M.get_highest_coincident(node)
  local parent = node:parent()
  -- prefer row over start on account of lisps / S-expressions, which start with (identifier, ..)
  while parent and M.have_same_row(node, parent) do
    if M.is_highlight_target(parent) then node = parent end
    parent = parent:parent()
  end
  return node
end

-- Easy conversion to table
---@param node TSNode
---@return [ integer, integer, integer, integer ]
function M.range(node)
  local r1, r2, r3, r4 = node:range()
  return { r1, r2, r3, r4 }
end

---@param node TSNode
---@return integer
function M.get_row(node)
  local row = node:range()
  return row + 1
end

---Get current node under cursor
---@return TSNode
function M.get_current()
  local node = vim.treesitter.get_node()
  assert(node)
  return node
end

---Get node at row/col
---@param row integer
---@param col integer
---@return TSNode|nil
function M.get_at_rowcol(row, col)
  return vim.treesitter.get_node({ pos = { row - 1, col } })
end

---Get node at row (after having pressed ^)
---@param row integer
---@return TSNode|nil
function M.get_at_row(row)
  local line = lines.get_line(row)
  local col = lines.get_start_col(line)
  return vim.treesitter.get_node({ pos = { row - 1, col } })
end

return M
