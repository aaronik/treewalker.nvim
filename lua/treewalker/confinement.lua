local anchor = require "treewalker.anchor"

local M = {}

---@param value TreewalkerAnchor | TSNode
---@return TreewalkerAnchor
local function as_anchor(value)
  if type(value) == "table" and value.node then
    return value
  end

  return anchor.from_node(value)
end

---@param current TreewalkerAnchor | TSNode
---@param candidate TreewalkerAnchor | TSNode
---@return boolean
function M.should_confine(current, candidate)
  local opts = require('treewalker').opts
  if opts.scope_confined ~= true then
    return false
  end

  local current_anchor = as_anchor(current)
  local current_parent = current_anchor.node:parent()
  if not current_parent then
    return false
  end

  local candidate_anchor = as_anchor(candidate)
  return not vim.treesitter.is_ancestor(current_parent, candidate_anchor.node)
end

return M
