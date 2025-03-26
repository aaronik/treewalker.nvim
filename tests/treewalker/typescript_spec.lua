local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("Swapping in a typescript file:", function()
  before_each(function()
    load_fixture("/typescript.ts")
  end)

  h.ensure_has_parser("typescript")

  it("swaps up annotated functions of different length", function()
    vim.fn.cursor(106, 1) -- |  const i = 1
    tw.swap_down()
    h.assert_cursor_at(107, 3)
    assert.same('  const j = 2', lines.get_line(106))
    assert.same('  const i = 1', lines.get_line(107))
  end)

  it("swaps down annotated functions of different length", function()
    vim.fn.cursor(107, 1) -- |  const i = 1
    tw.swap_up()
    h.assert_cursor_at(106, 3)
    assert.same('  const j = 2', lines.get_line(106))
    assert.same('  const i = 1', lines.get_line(107))
  end)
end)
