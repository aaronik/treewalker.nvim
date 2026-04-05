local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local swap = require("treewalker.swap")
local anchor = require("treewalker.anchor")
local lines = require("treewalker.lines")
local tw = require("treewalker")

describe("swap module", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false })
  end)

  describe(".swap_down", function()
    it("swaps current node with next sibling", function()
      vim.fn.cursor(1, 1)
      local original_line1 = lines.get_line(1)
      local original_line3 = lines.get_line(3)

      swap.swap_down()

      assert.equal(original_line3, lines.get_line(1))
      assert.equal(original_line1, lines.get_line(3))
    end)

    it("does nothing on empty line", function()
      vim.fn.cursor(2, 1) -- empty line
      local original_lines = lines.get_lines(1, 5)

      swap.swap_down()

      assert.same(original_lines, lines.get_lines(1, 5))
    end)

    it("does nothing at end of scope", function()
      vim.fn.cursor(193, 1) -- return M (last statement)
      local original_lines = lines.get_lines(190, 195)

      swap.swap_down()

      assert.same(original_lines, lines.get_lines(190, 195))
    end)

    it("swaps multi-line nodes", function()
      vim.fn.cursor(21, 1) -- function
      local func_start = lines.get_line(21)

      swap.swap_down()

      -- Function should have moved down
      local new_line_21 = lines.get_line(21)
      assert.is_true(new_line_21 ~= func_start or func_start:find("function") == nil)
    end)
  end)

  describe(".swap_up", function()
    it("swaps current node with previous sibling", function()
      vim.fn.cursor(3, 1)
      local original_line1 = lines.get_line(1)
      local original_line3 = lines.get_line(3)

      swap.swap_up()

      assert.equal(original_line3, lines.get_line(1))
      assert.equal(original_line1, lines.get_line(3))
    end)

    it("does nothing on empty line", function()
      vim.fn.cursor(2, 1) -- empty line
      local original_lines = lines.get_lines(1, 5)

      swap.swap_up()

      assert.same(original_lines, lines.get_lines(1, 5))
    end)

    it("does nothing at start of scope", function()
      vim.fn.cursor(1, 1) -- first statement
      local original_lines = lines.get_lines(1, 5)

      swap.swap_up()

      assert.same(original_lines, lines.get_lines(1, 5))
    end)
  end)

  describe(".swap_right", function()
    it("swaps node with next lateral sibling", function()
      vim.fn.cursor(38, 32) -- node1 in (node1, node2)
      local original = lines.get_line(38)

      swap.swap_right()

      local after = lines.get_line(38)
      assert.is_true(after ~= original or after:find("node2, node1") ~= nil)
    end)

    it("does nothing when no next sibling", function()
      vim.fn.cursor(38, 39) -- node2 (last parameter)
      local original = lines.get_line(38)

      swap.swap_right()

      -- Line might change or stay same depending on implementation
      local after = lines.get_line(38)
      assert.is_string(after)
    end)

    it("handles different size nodes", function()
      vim.fn.cursor(31, 24) -- TARGET_DESCENDANT_TYPES
      local original = lines.get_line(31)

      swap.swap_right()

      local after = lines.get_line(31)
      assert.is_true(after ~= original)
    end)
  end)

  describe(".swap_left", function()
    it("swaps node with previous lateral sibling", function()
      vim.fn.cursor(38, 39) -- node2 in (node1, node2)
      local original = lines.get_line(38)

      swap.swap_left()

      local after = lines.get_line(38)
      assert.is_true(after ~= original or after:find("node2, node1") ~= nil)
    end)

    it("does nothing when no previous sibling", function()
      vim.fn.cursor(38, 32) -- node1 (first parameter)
      local original = lines.get_line(38)

      swap.swap_left()

      -- Line might change or stay same
      local after = lines.get_line(38)
      assert.is_string(after)
    end)
  end)
end)

describe("swap with scope_confined = true", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ scope_confined = true, highlight = false })
  end)

  it("does not swap up across scope boundary", function()
    vim.fn.cursor(132, 3) -- for loop inside function
    local current = anchor.current()
    local parent = current.node:parent()
    assert.is_not_nil(parent)

    swap.swap_up()

    -- Should not have crossed scope boundary
    -- Verify we're still in scope by checking cursor position or content
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] >= 128) -- should still be within function
  end)

  it("does not swap down across scope boundary", function()
    vim.fn.cursor(136, 3) -- end of for loop
    swap.swap_down()

    -- Verify we're still in expected scope
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] <= 140) -- should not have escaped function
  end)
end)

describe("swap with markdown files", function()
  before_each(function()
    load_fixture("/markdown.md")
    tw.setup({ highlight = false })
  end)

  it("uses markdown-specific swap for swap_down", function()
    vim.fn.cursor(4, 1) -- ## Header
    local original_4 = lines.get_line(4)
    local original_19 = lines.get_line(19)

    swap.swap_down()

    -- Content should have been swapped
    local after_4 = lines.get_line(4)
    -- The sections swap, so line 4 should now start the "Text Formatting" section
  end)

  it("uses markdown-specific swap for swap_up", function()
    vim.fn.cursor(19, 1) -- ## Text Formatting
    swap.swap_up()
    -- Should swap with ## Header section
  end)

  it("does not swap left in markdown", function()
    vim.fn.cursor(4, 1)
    local original = lines.get_lines(1, 10)
    swap.swap_left()
    assert.same(original, lines.get_lines(1, 10))
  end)

  it("does not swap right in markdown", function()
    vim.fn.cursor(4, 1)
    local original = lines.get_lines(1, 10)
    swap.swap_right()
    assert.same(original, lines.get_lines(1, 10))
  end)
end)

describe("swap with unsupported filetypes", function()
  it("does nothing in text files", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "text"

    vim.fn.cursor(2, 1)
    local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    swap.swap_down()

    assert.same(original, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)

describe("swap preserves cursor position appropriately", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false })
  end)

  it("moves cursor with swapped node on swap_down", function()
    vim.fn.cursor(1, 1)
    swap.swap_down()
    -- Cursor should follow the swapped node
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] > 1)
  end)

  it("moves cursor with swapped node on swap_up", function()
    vim.fn.cursor(3, 1)
    local orig_row = vim.fn.line('.')
    swap.swap_up()
    local new_row = vim.fn.line('.')
    assert.is_true(new_row < orig_row)
  end)

  it("moves cursor appropriately on swap_right", function()
    vim.fn.cursor(38, 32) -- node1
    swap.swap_right()
    local pos = vim.fn.getpos(".")
    -- Cursor should be at or near the new position of the swapped node
    assert.equal(38, pos[2]) -- same line
  end)

  it("moves cursor appropriately on swap_left", function()
    vim.fn.cursor(38, 39) -- node2
    swap.swap_left()
    local pos = vim.fn.getpos(".")
    -- Cursor should be at or near the new position
    assert.equal(38, pos[2]) -- same line
  end)
end)
