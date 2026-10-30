local nodes = require "treewalker.nodes"
local anchor = require "treewalker.anchor"
local load_fixture = require "tests.load_fixture"

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
  it("compares byte and displayed indentation independently of jump eligibility", function()
    load_fixture("/lua.lua")
    local first = anchor.at_row(211)
    local second = anchor.at_row(212)
    local last = anchor.at_row(219)
    local nested = anchor.at_row(216)

    vim.bo.tabstop = 4
    assert.is_true(nodes.have_same_indent(first, second))
    assert.is_true(nodes.have_same_indent(second, first))
    assert.is_false(nodes.have_same_indent(first, nested))

    vim.bo.tabstop = 8
    assert.is_false(nodes.have_same_indent(first, second))
    assert.is_true(nodes.have_same_indent(first, last))
    assert.is_true(nodes.have_same_indent(first, nested))
  end)

  it("compares a comment's indentation without deciding whether it is a jump target", function()
    load_fixture("/yaml.yml")
    local comment = anchor.at_row(92)
    local key = anchor.at_row(90)

    assert.is_false(nodes.have_same_indent(comment, key))
  end)

  it("identifies transparent AST containers", function()
    local child = mock_node(nil, 2, 4)
    local transparent_container = mock_node(child, 2, 4)
    local opaque_container = mock_node(child, 2, 5)

    assert.is_true(nodes.is_transparent_container(transparent_container))
    assert.is_false(nodes.is_transparent_container(opaque_container))
  end)
end)
