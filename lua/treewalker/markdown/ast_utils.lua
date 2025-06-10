-- Shared AST utilities for markdown module
-- Provides common patterns and optimizations for Treesitter operations

local nodes = require "treewalker.nodes"

local M = {}

------------------------------------------------------------
-- Core AST utilities
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

------------------------------------------------------------
-- Generic traversal utilities
------------------------------------------------------------

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
---@param predicate function -- function(section_node, section_row, section_level) -> boolean|nil, integer|nil
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

return M