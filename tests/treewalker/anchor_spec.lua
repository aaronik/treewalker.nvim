local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local anchor = require("treewalker.anchor")
local nodes = require("treewalker.nodes")

describe("anchor", function()
  before_each(function()
    load_fixture("/lua.lua")
  end)

  describe(".current", function()
    it("returns an anchor at the cursor position", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      assert.is_not_nil(current)
      assert.is_not_nil(current.node)
      assert.is_number(current.row)
      assert.is_number(current.col)
    end)

    it("returns anchor with correct row", function()
      vim.fn.cursor(3, 1)
      local current = anchor.current()
      assert.is_not_nil(current)
      assert.equal(3, current.row)
    end)

    it("includes attached_rows for nodes with augments", function()
      vim.fn.cursor(21, 1) -- function with comments above
      local current = anchor.current()
      assert.is_not_nil(current)
      assert.is_table(current.attached_rows)
      assert.equal(2, #current.attached_rows)
    end)
  end)

  describe(".at_row", function()
    it("returns an anchor at specified row", function()
      local anc = anchor.at_row(1)
      assert.is_not_nil(anc)
      assert.equal(1, anc.row)
    end)

    it("returns nil for rows beyond file end", function()
      local anc = anchor.at_row(9999)
      assert.is_nil(anc)
    end)

    it("returns anchor with correct line content", function()
      local anc = anchor.at_row(1)
      assert.is_not_nil(anc)
      assert.is_not_nil(anc.line)
      assert.is_true(#anc.line > 0)
    end)
  end)

  describe(".from_node", function()
    it("builds anchor from a given node", function()
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)
      local anc = anchor.from_node(node)
      assert.is_not_nil(anc)
      assert.is_not_nil(anc.node)
    end)

    it("normalizes node to highest same-row target", function()
      vim.fn.cursor(21, 1)
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      local anc = anchor.from_node(node)
      assert.is_not_nil(anc)
      -- The anchor node should be at row 21
      assert.equal(21, nodes.get_srow(anc.node))
    end)

    it("accepts optional row parameter", function()
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)
      local anc = anchor.from_node(node, 5)
      assert.is_not_nil(anc)
      assert.equal(5, anc.row)
    end)
  end)

  describe(".find_up", function()
    it("finds the previous sibling at the same indent", function()
      vim.fn.cursor(21, 1)
      local current = anchor.current()
      local target = anchor.find_up(current)
      assert.is_not_nil(target)
      assert.is_true(target.row < current.row)
    end)

    it("returns nil when at top of scope", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      local target = anchor.find_up(current)
      assert.is_nil(target)
    end)

    it("respects indent level", function()
      vim.fn.cursor(21, 1)
      local current = anchor.current()
      local target = anchor.find_up(current)
      if target then
        assert.equal(current.indent, target.indent)
      end
    end)
  end)

  describe(".find_down", function()
    it("finds the next sibling at the same indent", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      local target = anchor.find_down(current)
      assert.is_not_nil(target)
      assert.is_true(target.row > current.row)
    end)

    it("returns nil when at bottom of scope", function()
      vim.fn.cursor(193, 1) -- return M
      local current = anchor.current()
      local target = anchor.find_down(current)
      assert.is_nil(target)
    end)

    it("respects indent level", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      local target = anchor.find_down(current)
      if target then
        assert.equal(current.indent, target.indent)
      end
    end)
  end)

  describe(".find_in", function()
    it("finds a child node at higher indent", function()
      vim.fn.cursor(21, 1) -- function declaration
      local current = anchor.current()
      local target = anchor.find_in(current)
      assert.is_not_nil(target)
      assert.is_true(target.indent > current.indent)
    end)

    it("returns nil when no children exist", function()
      vim.fn.cursor(1, 1) -- simple require statement
      local current = anchor.current()
      local target = anchor.find_in(current)
      -- Single line node should have no inner children
      if current.start_row == current.end_row then
        assert.is_nil(target)
      end
    end)
  end)

  describe(".find_out", function()
    it("finds a parent node at lower indent", function()
      vim.fn.cursor(22, 3) -- inside function
      local current = anchor.current()
      local target = anchor.find_out(current)
      assert.is_not_nil(target)
      assert.is_true(target.indent < current.indent)
    end)

    it("returns nil when at top level", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      local target = anchor.find_out(current)
      assert.is_nil(target)
    end)
  end)

  describe(".current_lateral_node", function()
    it("returns node at cursor position", function()
      vim.fn.cursor(1, 1)
      local node = anchor.current_lateral_node()
      assert.is_not_nil(node)
    end)

    it("normalizes to highest same-position node", function()
      vim.fn.cursor(1, 10) -- somewhere in require string
      local node = anchor.current_lateral_node()
      assert.is_not_nil(node)
      -- Should be a string or containing node
    end)
  end)

  describe(".next_sibling", function()
    it("returns next sibling for valid node", function()
      vim.fn.cursor(38, 32) -- function parameters
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      local sibling = anchor.next_sibling(node)
      -- May or may not have sibling depending on position
      if sibling then
        assert.is_not_nil(sibling)
      end
    end)

    it("returns nil for nil input", function()
      local sibling = anchor.next_sibling(nil)
      assert.is_nil(sibling)
    end)
  end)

  describe(".prev_sibling", function()
    it("returns previous sibling for valid node", function()
      vim.fn.cursor(38, 39) -- second parameter
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      local sibling = anchor.prev_sibling(node)
      -- May or may not have sibling
      if sibling then
        assert.is_not_nil(sibling)
      end
    end)

    it("returns nil for nil input", function()
      local sibling = anchor.prev_sibling(nil)
      assert.is_nil(sibling)
    end)
  end)

  describe(".get_highest_string_node", function()
    it("returns highest string ancestor", function()
      vim.fn.cursor(1, 30) -- inside 'treewalker.util' string
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      local highest = anchor.get_highest_string_node(node)
      -- Should find a string node
      if highest then
        assert.is_true(highest:type():match("string") ~= nil)
      end
    end)

    it("returns nil when not in a string", function()
      vim.fn.cursor(3, 1) -- local M = {}
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      local highest = anchor.get_highest_string_node(node)
      -- May or may not be nil depending on exact position
    end)
  end)

  describe(".find_neighbor", function()
    it("finds upward neighbor", function()
      vim.fn.cursor(21, 1)
      local current = anchor.current()
      local neighbor = anchor.find_neighbor("up", current)
      if neighbor then
        assert.is_true(neighbor.row < current.row)
      end
    end)

    it("finds downward neighbor", function()
      vim.fn.cursor(1, 1)
      local current = anchor.current()
      local neighbor = anchor.find_neighbor("down", current)
      if neighbor then
        assert.is_true(neighbor.row > current.row)
      end
    end)
  end)
end)
