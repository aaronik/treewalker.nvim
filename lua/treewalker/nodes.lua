local lines = require "treewalker.lines"
local util = require "treewalker.util"

-- These are regexes but just happen to be real simple so far
local TARGET_BLACKLIST_TYPE_MATCHERS = {
  "comment",
  "attribute_item", -- decorators (rust)
  "decorat",        -- decorators (py)
  "else",           -- else/elseif statements (lua)
  "elif",           -- else/elseif statements (py)
}

local HIGHLIGHT_BLACKLIST_TYPE_MATCHERS = {
  "body",
  "block",
}

local AUGMENT_TARGET_TYPE_MATCHERS = {
  "comment",
  "attribute_item", -- decorators (rust)
  "decorat",        -- decorators (py)
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

function M.is_augment_target(node)
  return
      true
      and is_matched_in(node, AUGMENT_TARGET_TYPE_MATCHERS)
      and not is_root_node(node)
end

---Do the nodes have the same starting row
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.have_same_srow(node1, node2)
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

-- Take row, give next row / node with same indentation
---@param current_row integer
---@param dir "up" | "down"
---@return TSNode | nil, integer | nil, string | nil
function M.get_from_neighboring_line(current_row, dir)
  local candidate_row
  if dir == "up" then
    candidate_row = current_row - 1
  else
    candidate_row = current_row + 1
  end
  local max_row = vim.api.nvim_buf_line_count(0)
  if candidate_row > max_row or candidate_row <= 0 then return end
  local candidate_line = lines.get_line(candidate_row)
  local candidate = M.get_at_row(candidate_row)

  -- For py decorators, when we examine the target-ness of a node, we
  -- want to be checking the highest coincident, rather than checking
  -- an inner node, then going up to highest coincident. Check the ultimate
  -- node kinda thing, rather than checking a child and then assuming
  -- its highest node will be good.
  if candidate then
    candidate = M.get_highest_row_coincident(candidate)
  end

  return candidate, candidate_row, candidate_line
end

-- Get farthest ancestor (or self) at the same starting row
-- This method prefers row over start on account of lisps / S-expressions,
-- which start with (identifier, ..). This is used for all up/down movement/swapping
---@param node TSNode
---@return TSNode
function M.get_highest_row_coincident(node)
  local parent = node:parent()
  while parent and M.have_same_srow(node, parent) do
    if M.is_highlight_target(parent) then node = parent end
    parent = parent:parent()
  end
  return node
end

-- Get farthest ancestor (or self) at the same starting row/col
---@param node TSNode
---@return TSNode
function M.get_highest_coincident(node)
  local parent = node:parent()
  while parent and M.have_same_srow(node, parent) and M.have_same_scol(node, parent) do
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

-- gets the smallest line number range that contains all given nodes
---@param nodes TSNode[]
---@return [ integer, integer ]
function M.whole_range(nodes)
  local min_row = math.huge
  local max_row = -math.huge

  for _, node in ipairs(nodes) do
    local srow, _, erow = node:range()
    if srow < min_row then min_row = srow end
    if erow > max_row then max_row = erow end
    if srow > max_row then max_row = srow end
  end

  return { min_row, max_row }
end

-- Apparently the LSP speaks ranges in a different way from treesitter,
-- and this is important for swapping nodes
---@param node TSNode
---@return { start: { line: integer, character: integer }, end: { line: integer, character: integer }  }
function M.lsp_range(node)
  local start_line, start_col, end_line, end_col = node:range()
  return {
    start = { line = start_line, character = start_col },
    ["end"] = { line = end_line, character = end_col }
  }
end

---Get the given node's text
---@param node TSNode
function M.get_text(node)
  -- We have to remember that end_col is end-exclusive
  local start_row, start_col, end_row, end_col = node:range()

  if start_row ~= end_row then
    local lins = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
    if next(lins) == nil then
      return {}
    end
    lins[1] = string.sub(lins[1], start_col + 1)
    -- end_row might be just after the last line. In this case the last line is not truncated.
    if #lins == end_row - start_row + 1 then
      lins[#lins] = string.sub(lins[#lins], 1, end_col)
    end
    return lins
  else
    local line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
    -- If line is nil then the line is empty
    return line and { string.sub(line, start_col + 1, end_col) } or {}
  end
end

-- get 1-indexed row of given node
-- (so will work directly with vim.fn.cursor,
-- and will reflect row as seen in the vim status line)
---@param node TSNode
---@return integer
function M.get_row(node)
  local row = node:range()
  return row + 1
end

-- get 1-indexed column of given node
-- (so will work directly with vim.fn.cursor,
-- and will reflect col as seen in the vim status line)
---@param node TSNode
---@return integer
function M.get_col(node)
  local _, col = node:range()
  return col + 1
end

---Get highest node at row/col
---@param row integer
---@param col integer
---@return TSNode|nil
function M.get_at_rowcol(row, col)
  local node = vim.treesitter.get_node({ pos = { row - 1, col } })
  if node then
    return M.get_highest_coincident(node)
  end
end

---Get node at row (after having pressed ^)
---@param row integer
---@return TSNode|nil
function M.get_at_row(row)
  local line = lines.get_line(row)
  if not line then return end
  local col = lines.get_start_col(line)
  local node = vim.treesitter.get_node({ pos = { row - 1, col } })
  if node then
    return M.get_highest_row_coincident(node)
  end
end

---Get highest node on current row
---@return TSNode
function M.get_row_current()
  local node = vim.treesitter.get_node()
  assert(node)
  -- TODO this practice is breaking moving out of haskell functions
  return M.get_highest_row_coincident(node)
end

---Get highest node at same row/col
---@return TSNode
function M.get_current()
  local node = vim.treesitter.get_node()
  assert(node)
  return M.get_highest_coincident(node)
end

-- util.log some formatted version of the node's properties
---@param node TSNode
---@return nil
function M.log(node)
  local row = M.range(node)[1] + 1
  local line = lines.get_line(row)
  assert(line, "log should only ever be called on valid nodes which will have valid line numbers")
  local col = lines.get_start_col(line)
  local log_string = ""
  log_string = log_string .. string.format(" [%s/%s]", row, col)
  log_string = log_string .. string.format(" (%s)", node:type())
  log_string = log_string .. string.format(" |%s|", line)
  log_string = log_string .. string.format(" {%s}", vim.inspect(M.range(node)))
  util.log(log_string)
end

-- util.log some formatted version of the node's parent chain
---@param node TSNode
---@return nil
function M.log_parents(node)
  local log_string = node:type()
  if node:parent() then
    log_string = node:parent():type() .. "->" .. log_string
  end
  if node:parent():parent() then
    log_string = node:parent():parent():type() .. "->" .. node:parent():type() .. "->" .. log_string
  end
  util.log(log_string)
end

return M
