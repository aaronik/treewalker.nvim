local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local lines = require 'treewalker.lines'

describe("In a ruby file: ", function()
  before_each(function()
    load_fixture("/ruby.rb")
  end)

  h.ensure_has_parser("ruby")

  it("moves around", function()
    vim.fn.cursor(6, 3)
    tw.move_down()
    h.assert_cursor_at(12, 3)
    tw.move_down()
    h.assert_cursor_at(22, 3)
    tw.move_up()
    h.assert_cursor_at(12, 3)
  end)

  it("swaps up", function()
    local first_block = lines.get_lines(5, 9)
    local second_block = lines.get_lines(11, 19)
    vim.fn.cursor(12, 3)
    tw.swap_up()
    assert.same(second_block, lines.get_lines(5, 13))
    assert.same(first_block, lines.get_lines(15, 19))
    h.assert_cursor_at(6, 3)
  end)

  it("swaps down", function()
    local first_block = lines.get_lines(5, 9)
    local second_block = lines.get_lines(11, 19)
    vim.fn.cursor(6, 3)
    tw.swap_down()
    assert.same(second_block, lines.get_lines(5, 13))
    assert.same(first_block, lines.get_lines(15, 19))
    h.assert_cursor_at(16, 3)
  end)
  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(19, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(20, 1, 'up')
    end)
  end)
end)
