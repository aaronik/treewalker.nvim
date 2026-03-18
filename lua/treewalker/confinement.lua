local nodes = require "treewalker.nodes"

local M = {}

---@param current_node TSNode
---@param candidate TSNode
---@return boolean
function M.should_confine(current_node, candidate)
  local opts = require('treewalker').opts
  if opts.scope_confined ~= true then
    return false
  end

  local current_parent = nodes.scope_parent(current_node)
  if not current_parent then
    return false
  end

  local candidate_anchor = nodes.get_highest_row_coincident(candidate)
  return not nodes.is_descendant_of(current_parent, candidate_anchor)
end

return M
