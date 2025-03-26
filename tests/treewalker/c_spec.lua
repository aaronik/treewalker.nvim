local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local lines = require 'treewalker.lines'

describe("In a c file:", function()
  before_each(function()
    load_fixture("/c.c")
  end)

  h.ensure_has_parser("c")

  it("Moves around", function()
    vim.fn.cursor(46, 1)
    tw.move_down()
    h.assert_cursor_at(50, 1, "int main")
    tw.move_down()
    h.assert_cursor_at(64, 1)
    tw.move_down()
    h.assert_cursor_at(69, 1)
  end)

  it("swaps right, when cursor is inside a string, the whole string", function()
    vim.fn.cursor(14, 17) -- the o in one
    assert.same('        printf("one\\n", "two\\n");', lines.get_line(14))
    tw.swap_right()
    assert.same('        printf("two\\n", "one\\n");', lines.get_line(14))
  end)

  it("swaps left, when cursor is inside a string, the whole string", function()
    vim.fn.cursor(17, 28) -- the t in two
    assert.same('        printf("one\\n", "\\ntwo\\n");', lines.get_line(17))
    tw.swap_left()
    assert.same('        printf("\\ntwo\\n", "one\\n");', lines.get_line(17))
  end)

  it("swaps down on next line bracket structured functions", function()
    local first_block = lines.get_lines(63, 67)
    local second_block = lines.get_lines(69, 72)
    vim.fn.cursor(64, 1)
    tw.swap_down()
    assert.same(first_block, lines.get_lines(68, 72))
    assert.same(second_block, lines.get_lines(63, 66))
  end)

  it("swaps up on next line bracket structured functions", function()
    local first_block = lines.get_lines(63, 67)
    local second_block = lines.get_lines(69, 72)
    vim.fn.cursor(69, 1)
    tw.swap_up()
    assert.same(first_block, lines.get_lines(68, 72))
    assert.same(second_block, lines.get_lines(63, 66))
  end)
end)
