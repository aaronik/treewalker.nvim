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

return M