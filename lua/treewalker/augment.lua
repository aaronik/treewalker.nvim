local nodes = require("treewalker.nodes")

local M = {}

-- Gets the "augment" nodes that exist above a given node
-- These are nodes that are, like, kind of attached to the provided node.
-- Think comments, decorators, annotations, etc. Stuff that wants to stay
-- with the given node. This was originally implemented to aid with
-- up/down swapping, because if you swap a node that has a comment description,
-- comment types, annotations, etc, those should move along with the node.
---@param node TSNode
---@return TSNode[]
function M.get_node_augments(node)
  local row = nodes.get_srow(node)
  local augments = {}
  while true do
    local candidate = nodes.get_from_neighboring_line(row, "up")
    if candidate and nodes.is_augment_target(candidate) then
      table.insert(augments, candidate)
      row = nodes.get_srow(candidate)
    else
      break
    end
  end

  return augments
end

return M
