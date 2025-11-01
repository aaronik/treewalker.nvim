local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local helpers = require 'tests.treewalker.helpers'

describe("CI environment simulation:", function()
  before_each(function()
    tw.setup()
    -- Set tabstop to 2 like CI environment
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.expandtab = true
  end)

  after_each(function()
    -- Restore to default
    vim.opt.tabstop = 8
    vim.opt.shiftwidth = 8
  end)

  describe("TypeScript comment navigation with tabstop=2", function()
    before_each(function()
      load_fixture("/typescript.ts")
    end)

    it("moves out from comment to class declaration (cursor at column 1)", function()
      vim.fn.cursor(121, 1) -- At "/**" at column 1 (in whitespace)
      tw.move_out()
      helpers.assert_cursor_at(119, 1, "|class Ok")
    end)

    it("moves out from comment to class declaration (cursor at column 2)", function()
      vim.fn.cursor(121, 2) -- At first "*" in "/**"
      tw.move_out()
      helpers.assert_cursor_at(119, 1, "|class Ok")
    end)

    it("moves out from comment to class declaration (cursor at column 3)", function()
      vim.fn.cursor(121, 3) -- At second "*" in "/**"
      tw.move_out()
      helpers.assert_cursor_at(119, 1, "|class Ok")
    end)

    it("moves out from comment to class declaration (cursor mid-comment)", function()
      vim.fn.cursor(122, 5) -- Inside "* whats blah blah"
      tw.move_out()
      helpers.assert_cursor_at(119, 1, "|class Ok")
    end)

    it("moves down from indented comment block", function()
      vim.fn.cursor(115, 3) -- At indented comment inside multiline comment
      tw.move_down()
      helpers.assert_cursor_at(117, 1, "|const whatever")
    end)

    it("moves down from inside a comment", function()
      vim.fn.cursor(122, 5) -- Inside "* whats blah blah"
      tw.move_down()
      helpers.assert_cursor_at(124, 3, "|constructor")
    end)

    it("moves down from Ok class comment to constructor", function()
      vim.fn.cursor(121, 3) -- At "/**"
      tw.move_down()
      helpers.assert_cursor_at(124, 3, "|constructor")
    end)
  end)

  describe("Cursor normalization with different tabstop settings", function()
    it("normalizes cursor from whitespace before querying node (Lua file)", function()
      load_fixture("/lua.lua")
      -- Position cursor inside a table at row 22 with "  for _,"
      vim.fn.cursor(22, 1) -- In leading whitespace
      tw.move_out()
      -- Should successfully move out to the function containing this table
      helpers.assert_cursor_at(21, 1, "|local function")
    end)

    it("handles cursor at various positions on same line (TypeScript)", function()
      load_fixture("/typescript.ts")
      local target_row = 119

      -- Test from column 1 (whitespace)
      vim.fn.cursor(121, 1)
      tw.move_out()
      helpers.assert_cursor_at(target_row, 1)

      -- Test from column 2 (first non-whitespace)
      vim.fn.cursor(121, 3)
      tw.move_out()
      helpers.assert_cursor_at(target_row, 1)

      -- Test from middle of line
      vim.fn.cursor(121, 5)
      tw.move_out()
      helpers.assert_cursor_at(target_row, 1)
    end)
  end)

  describe("Node querying consistency with tabstop=2", function()
    it("gets same node regardless of cursor position on line (move_out)", function()
      load_fixture("/typescript.ts")

      -- Move out from different positions on line 121 should all go to same target
      vim.fn.cursor(121, 1)
      tw.move_out()
      local target1 = vim.fn.line('.')

      vim.fn.cursor(121, 3)
      tw.move_out()
      local target2 = vim.fn.line('.')

      vim.fn.cursor(121, 5)
      tw.move_out()
      local target3 = vim.fn.line('.')

      assert.equals(target1, target2, "Target should be same from col 1 and col 3")
      assert.equals(target2, target3, "Target should be same from col 3 and col 5")
      assert.equals(119, target1, "All should target class declaration at row 119")
    end)

    it("gets same node regardless of cursor position on line (move_down)", function()
      load_fixture("/typescript.ts")

      -- Move down from different positions on line 121 should all go to same target
      vim.fn.cursor(121, 1)
      tw.move_down()
      local target1 = vim.fn.line('.')

      vim.fn.cursor(121, 3)
      tw.move_down()
      local target2 = vim.fn.line('.')

      assert.equals(target1, target2, "Target should be same regardless of cursor col")
      assert.equals(124, target1, "Should target constructor at row 124")
    end)
  end)
end)
