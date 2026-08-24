local nodes = require "treewalker.nodes"

---@class MockNode
---@field child MockNode|nil
---@field start_row integer
---@field start_col integer

---@param child MockNode|nil
---@param start_row integer
---@param start_col integer
---@return MockNode
local function mock_node(child, start_row, start_col)
  local node = {
    child = child,
    start_row = start_row,
    start_col = start_col,
  }

  function node:named_child(index)
    if index == 0 then return self.child end
  end

  function node:range()
    return self.start_row, self.start_col, self.start_row, self.start_col
  end

  return node
end

describe("nodes", function()
  it("identifies transparent AST containers", function()
    local child = mock_node(nil, 2, 4)
    local transparent_container = mock_node(child, 2, 4)
    local opaque_container = mock_node(child, 2, 5)

    assert.is_true(nodes.is_transparent_container(transparent_container))
    assert.is_false(nodes.is_transparent_container(opaque_container))
  end)
end)
