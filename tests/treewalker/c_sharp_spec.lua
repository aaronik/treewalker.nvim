local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local lines = require 'treewalker.lines'

describe("In a C Sharp file", function()
  before_each(function()
    load_fixture("/c-sharp.cs")
  end)

  h.ensure_has_parser("c_sharp")

  it("moves around", function()
    vim.fn.cursor(7, 5)
    tw.move_down()
    h.assert_cursor_at(27, 5)
    tw.move_down()
    h.assert_cursor_at(50, 5)
    tw.move_in()
    h.assert_cursor_at(52, 9)
    tw.move_out()
    h.assert_cursor_at(50, 5)
  end)

  it("swaps down", function()
    vim.fn.cursor(7, 5)
    local first_block = lines.get_lines(6, 24)
    local second_block = lines.get_lines(26, 48)
    tw.swap_down()
    assert.same(second_block, lines.get_lines(6, 28))
    assert.same(first_block, lines.get_lines(30, 48))
    h.assert_cursor_at(31, 5)
  end)

  it("swaps up", function()
    vim.fn.cursor(27, 5)
    local first_block = lines.get_lines(6, 24)
    local second_block = lines.get_lines(26, 48)
    tw.swap_up()
    assert.same(second_block, lines.get_lines(6, 28))
    assert.same(first_block, lines.get_lines(30, 48))
    h.assert_cursor_at(7, 5)
  end)

  it("swaparound behavior works", function()
    vim.fn.cursor(52, 31)
    tw.swap_left()
    assert.same("        public static int Add(int b, int a) => a + b;", lines.get_line(52))
    tw.swap_right()
    assert.same("        public static int Add(int a, int b) => a + b;", lines.get_line(52))
  end)
end)
