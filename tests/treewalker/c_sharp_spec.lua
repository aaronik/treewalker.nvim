local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local lines = require 'treewalker.lines'

describe("Movement in a C Sharp file", function()
  before_each(function()
    load_fixture("/c-sharp.cs")
  end)

  it("works", function()
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
end)

describe("Swapping in a C Sharp file", function()
  before_each(function()
    load_fixture("/c-sharp.cs")
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
end)
