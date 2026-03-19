local lines = require "treewalker.lines"

local M = {}

---Do the nodes have the same starting row
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
function M.have_same_srow(node1, node2)
  return M.get_srow(node1) == M.get_srow(node2)
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

---Return the root TSNode for the given buffer (defaults to current buffer).
---Safe wrapper around parser/parse() that handles missing parsers and empty parse results.
---@param bufnr integer|nil
---@return TSNode|nil
function M.get_root(bufnr)
  bufnr = bufnr or 0
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok_parser or not parser then
    return nil
  end

  local ok_parse, trees = pcall(function() return parser:parse() end)
  if not ok_parse or not trees or #trees == 0 then
    return nil
  end

  local ok_root, root = pcall(function() return trees[1]:root() end)
  if not ok_root then
    return nil
  end

  return root
end


---Get the given node's text
---@param node TSNode
---@return string[]
function M.get_lines(node)
  local text = vim.treesitter.get_node_text(node, 0, {})
  return vim.split(text, "\n")
end

-- get 1-indexed start row of given node
-- (so will work directly with vim.fn.cursor,
-- and will reflect row as seen in the vim status line)
---@param node TSNode
---@return integer
function M.get_srow(node)
  local row = node:range()
  return row + 1
end

-- get 1-indexed end row of given node
-- (so will work directly with vim.fn.cursor,
-- and will reflect row as seen in the vim status line)
---@param node TSNode
---@return integer
function M.get_erow(node)
  local _, _, row = node:range()
  return row + 1
end

-- get 1-indexed start column of given node
-- (so will work directly with vim.fn.cursor,
-- and will reflect col as seen in the vim status line)
---@param node TSNode
---@return integer
function M.get_scol(node)
  local _, col = node:range()
  return col + 1
end

---Get node at row (after having pressed ^)
---@param row integer
---@return TSNode|nil
function M.get_at_row(row)
  local line = lines.get_line(row)
  if not line then return end
  local col = lines.get_start_col(line)
  return vim.treesitter.get_node({
    pos = { row - 1, col - 1 },
    ignore_injections = false,
  })
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

return M
