-- Markdown heading/section/relationship API for Treewalker.nvim
-- Uses Treesitter AST exclusively

local util = require "treewalker.util"
local nodes = require "treewalker.nodes"
local ast_utils = require "treewalker.markdown.ast_utils"

local M = {}

------------------------------------------------------------
-- Heading info extraction using Treesitter AST
------------------------------------------------------------

--- Extract heading info using treesitter
---@param row integer
---@return {type: string, level?: integer}
function M.heading_info(row)
  local node = nodes.get_at_row(row)
  if not node then return { type = "none" } end

  -- Find if we're in an atx_heading node
  local current = node --[[@as TSNode?]]
  while current do
    if current:type() == "atx_heading" then
      local level = ast_utils.get_heading_level_from_node(current)
      if level then
        return { type = "heading", level = level }
      end
    end
    current = current:parent()
  end

  return { type = "none" }
end

--- Returns heading level for a row or nil if not on heading
---@param row integer
---@return integer|nil
function M.heading_level(row)
  local info = M.heading_info(row)
  return info.type == "heading" and info.level or nil
end

--- Does this row contain a heading?
---@param row integer
---@return boolean
function M.is_heading(row)
  local info = M.heading_info(row)
  return info.type == "heading"
end

------------------------------------------------------------
-- Heading relationships (siblings, parent, child)
------------------------------------------------------------

--- Are two rows headings at the same level?
---@param row1 integer
---@param row2 integer
---@return boolean
function M.is_sibling(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h1.level == h2.level
end

--- Is row1 the parent heading of row2?
---@param row1 integer
---@param row2 integer
---@return boolean
function M.is_parent(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h2.level == h1.level - 1
end

--- Is row1 the child heading of row2?
---@param row1 integer
---@param row2 integer
---@return boolean
function M.is_child(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h2.level == h1.level + 1
end

------------------------------------------------------------
-- Section detection utilities (bounds etc)
------------------------------------------------------------

--- Returns (level, start_row, end_row) for the section containing row using treesitter.
---@param row integer
---@return integer|nil, integer|nil, integer|nil
function M.get_section_bounds(row)
  if not util.is_markdown_file() then return nil, nil, nil end

  -- Find the section node that contains a heading at this row
  local root = nodes.get_root()
  if not root then return nil, nil, nil end

  local function find_section_with_heading_at_row(node)
    if node:type() == "section" then
      local heading_row, heading_node = ast_utils.get_section_heading_row_and_node(node)
      if heading_row == row then
        return node, heading_row, heading_node
      end
    end

    for child in node:iter_children() do
      local sec, hr, hn = find_section_with_heading_at_row(child)
      if sec then return sec, hr, hn end
    end

    return nil, nil, nil
  end

  local section, heading_row, heading_node = find_section_with_heading_at_row(root)
  if not section then return nil, nil, nil end

  local level = nil
  if heading_node then
    level = ast_utils.get_heading_level_from_node(heading_node)
  end

  if not level or not heading_row then return nil, nil, nil end

  local _, _, section_end_row, _ = section:range()

  return level, heading_row, section_end_row
end

--- Finds the parent heading row and its level for a heading at row using treesitter.
---@param row integer
---@param level integer
---@return integer|nil, integer|nil
function M.find_parent_header(row, level)
  local node = nodes.get_at_row(row)
  if not node then return nil, nil end

  -- Find the current section
  local section = node --[[@as TSNode?]]
  while section do
    if section:type() == "section" then
      break
    end
    section = section:parent()
  end

  if not section then return nil, nil end

  -- Look for parent section
  local parent = section:parent()
  while parent do
    if parent:type() == "section" then
      -- Get the heading level of this parent section using ast_utils
      local heading_child = ast_utils.find_child_of_type(parent, "atx_heading")
      if heading_child then
        local parent_level = ast_utils.get_heading_level_from_node(heading_child)
        if parent_level and parent_level < level then
          return nodes.get_srow(heading_child), parent_level
        end
      end
    end
    parent = parent:parent()
  end

  return nil, nil
end

--- Returns the section bounds of the parent heading.
---@param row integer
---@param level integer
---@return integer|nil, integer|nil, integer|nil
function M.get_parent_section_bounds(row, level)
  local parent_row, parent_level = M.find_parent_header(row, level)
  if parent_row and parent_level then
    return M.get_section_bounds(parent_row)
  end
  return nil, 1, vim.api.nvim_buf_line_count(0)
end

return M
