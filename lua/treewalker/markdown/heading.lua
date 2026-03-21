-- Markdown heading/section/relationship API for Treewalker.nvim
-- Uses Treesitter AST exclusively

local util = require "treewalker.util"
local nodes = require "treewalker.nodes"

local M = {}

------------------------------------------------------------
-- Shared AST utilities
------------------------------------------------------------

--- Extract heading level from an atx_heading node
---@param heading_node TSNode
---@return integer|nil
function M.get_heading_level_from_node(heading_node)
  for marker_child in heading_node:iter_children() do
    local marker_type = marker_child:type()
    if marker_type:match("^atx_h(%d)_marker$") then
      return tonumber(marker_type:match("^atx_h(%d)_marker$"))
    end
  end
  return nil
end

--- Get section heading row and node from a section
---@param section_node TSNode
---@return integer|nil, TSNode|nil
function M.get_section_heading_row_and_node(section_node)
  for child in section_node:iter_children() do
    if child:type() == "atx_heading" then
      return nodes.get_srow(child), child
    end
  end
  return nil, nil
end

--- Get section level from a section node
---@param section_node TSNode
---@return integer|nil
function M.get_section_level(section_node)
  for child in section_node:iter_children() do
    if child:type() == "atx_heading" then
      return M.get_heading_level_from_node(child)
    end
  end
  return nil
end

--- Find first child of specified type
---@param node TSNode
---@param child_type string
---@return TSNode|nil
function M.find_child_of_type(node, child_type)
  for child in node:iter_children() do
    if child:type() == child_type then
      return child
    end
  end
  return nil
end

--- Generic section traversal helper
---@param root TSNode
---@param predicate function
---@return TSNode|nil, integer|nil
function M.find_section_matching(root, predicate)
  local function traverse(node)
    if node:type() == "section" then
      local section_row = M.get_section_heading_row_and_node(node)
      local section_level = M.get_section_level(node)

      if section_row then
        local should_return, custom_row = predicate(node, section_row, section_level)
        if should_return then
          local target_row = custom_row or section_row
          return nodes.get_at_row(target_row), target_row
        end
      end
    end

    for child in node:iter_children() do
      local result_node, result_row = traverse(child)
      if result_node then return result_node, result_row end
    end

    return nil, nil
  end

  return traverse(root)
end

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
        local level = M.get_heading_level_from_node(current)

      if level then
        return { type = "heading", level = level }
      end
    end
    current = current:parent()
  end

  return { type = "none" }
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
        local heading_row, heading_node = M.get_section_heading_row_and_node(node)

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
      level = M.get_heading_level_from_node(heading_node)

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
        local heading_child = M.find_child_of_type(parent, "atx_heading")

      if heading_child then
          local parent_level = M.get_heading_level_from_node(heading_child)

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
