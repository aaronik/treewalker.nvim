local util = require "treewalker.util"
local load_fixture = require "tests.load_fixture"
local stub = require 'luassert.stub'
local assert = require "luassert"
local treewalker = require 'treewalker'
local ops = require 'treewalker.ops'

-- Assert the cursor is in the expected position
---@param line integer
---@param column integer
---@param msg string?
local function assert_cursor_at(line, column, msg)
  local cursor_pos = vim.fn.getpos('.')
  ---@type integer, integer
  local current_line, current_column
  current_line, current_column = cursor_pos[2], cursor_pos[3]
  msg = string.format("expected to be at [%s] but wasn't", msg)
  assert.are.same({ line, column }, { current_line, current_column }, msg)
end

describe("Treewalker", function()
  describe("regular lua file: ", function()
    load_fixture("/lua.lua", "lua")

    it("moves up and down at the same pace", function()
      vim.fn.cursor(1, 1) -- Reset cursor
      treewalker.move_down()
      assert_cursor_at(3, 1)
      treewalker.move_down()
      assert_cursor_at(5, 1)
      treewalker.move_down()
      assert_cursor_at(10, 1)
      treewalker.move_down()
      assert_cursor_at(21, 1)
      treewalker.move_up()
      assert_cursor_at(10, 1)
      treewalker.move_up()
      assert_cursor_at(5, 1)
      treewalker.move_up()
      assert_cursor_at(3, 1)
      treewalker.move_up()
      assert_cursor_at(1, 1)
    end)

    it("doesn't consider empty lines to be outer scopes", function()
      vim.fn.cursor(85, 1)
      treewalker.move_down()
      assert_cursor_at(88, 3, "local")

      vim.fn.cursor(85, 1)
      treewalker.move_up()
      assert_cursor_at(84, 3, "end")
    end)

    it("goes into functions eagerly", function()
      vim.fn.cursor(143, 1) -- In a bigger function
      treewalker.move_in()
      assert_cursor_at(144, 3)
      treewalker.move_in()
      assert_cursor_at(147, 5)
      treewalker.move_in()
      assert_cursor_at(149, 7)
    end)

    it("doesn't jump into a comment", function()
      vim.fn.cursor(177, 1) -- In a bigger function
      treewalker.move_in()
      assert_cursor_at(179, 3, "local")
    end)

    it("goes out of functions", function()
      vim.fn.cursor(149, 7) -- In a bigger function
      treewalker.move_out()
      assert_cursor_at(148, 5, "if")
      treewalker.move_out()
      assert_cursor_at(146, 3, "while")
      treewalker.move_out()
      assert_cursor_at(143, 1, "function")
    end)

    it("respects highlight config option", function()
      local highlight_stub = stub(ops, "highlight")
      treewalker.setup() -- highlight defaults to true, doesn't blow up with empty setup
      vim.fn.cursor(23, 5)
      treewalker.move_out()
      treewalker.move_down()
      treewalker.move_up()
      treewalker.move_in()
      assert.equal(4, #highlight_stub.calls)

      highlight_stub = stub(ops, "highlight")
      treewalker.setup({ highlight = false })
      vim.fn.cursor(23, 5)
      treewalker.move_out()
      treewalker.move_down()
      treewalker.move_up()
      treewalker.move_in()
      assert.equal(0, #highlight_stub.calls)

      highlight_stub = stub(ops, "highlight")
      treewalker.setup({ highlight = true })
      vim.fn.cursor(23, 5)
      treewalker.move_out()
      treewalker.move_down()
      treewalker.move_up()
      treewalker.move_in()
      assert.equal(4, #highlight_stub.calls)
    end)
  end)

  describe("lua spec file: ", function()
    load_fixture("/lua-spec.lua", "lua")

    -- go to first describe
    local function go_to_describe()
      vim.fn.cursor(1, 1)
      for _ = 1, 6 do
        treewalker.move_down()
      end
      assert_cursor_at(17, 1, "describe")
    end

    -- go to first load_buf
    local function go_to_load_buf()
      go_to_describe()
      treewalker.move_in(); treewalker.move_in()
      assert_cursor_at(19, 5, "load_buf")
    end

    it("moves up and down at the same pace", function()
      go_to_load_buf()
      treewalker.move_down(); treewalker.move_down()
      assert_cursor_at(41, 5, "it")
      treewalker.move_up(); treewalker.move_up()
      assert_cursor_at(19, 5, "load_buf")
    end)

    it("down moves at least one line", function()
      go_to_load_buf()
      treewalker.move_down()
      assert_cursor_at(21, 5, "it")
    end)
  end)
end)
