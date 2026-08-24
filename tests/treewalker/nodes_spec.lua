local load_fixture = require "tests.load_fixture"
local nodes = require "treewalker.nodes"

describe("nodes", function()
  before_each(function()
    load_fixture("/go.go")
  end)

  it("identifies transparent AST containers", function()
    local root = nodes.get_root()
    assert(root)

    local function_declaration = nil
    local root_children = root:iter_children()
    local child = root_children()
    while child do
      if child:named() and child:type() == "function_declaration" then
        function_declaration = child
        break
      end
      child = root_children()
    end
    assert(function_declaration)

    local block = nil
    local function_children = function_declaration:iter_children()
    child = function_children()
    while child do
      if child:named() and child:type() == "block" then
        block = child
        break
      end
      child = function_children()
    end
    assert(block)
    local statement_list = block:named_child(0)
    assert(statement_list)

    assert.is_true(nodes.have_same_start(statement_list, statement_list:named_child(0)))
    assert.is_true(nodes.is_transparent_container(statement_list))
    assert.is_false(nodes.is_transparent_container(function_declaration))
  end)
end)
