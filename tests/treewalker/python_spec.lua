local load_fixture = require("tests.load_fixture")
local assert = require("luassert")
local tw = require("treewalker")
local lines = require("treewalker.lines")
local h = require("tests.treewalker.helpers")

describe("In a python file: ", function()
  before_each(function()
    load_fixture("/python.py")
  end)

  h.ensure_has_parser("python")

  it("move_in doesn't land on non target nodes", function()
    vim.fn.cursor(54, 1)
    tw.move_in()
    h.assert_cursor_at(56, 5)
  end)

  it("Moves into the body of a function with multiline signature", function()
    vim.fn.cursor(131, 3) -- de|f
    tw.move_in()
    h.assert_cursor_at(132, 5)
    tw.move_down()
    h.assert_cursor_at(133, 5)
    tw.move_down()
    h.assert_cursor_at(134, 5)
    tw.move_down()
    h.assert_cursor_at(136, 5)
  end)

  it("swaps up annotated functions of different length", function()
    vim.fn.cursor(143, 1) -- |def handler_bottom
    local top_before = lines.get_lines(123, 136)
    local bottom_before = lines.get_lines(138, 148)

    tw.swap_up()

    h.assert_cursor_at(128, 1)
    assert.same(bottom_before, lines.get_lines(123, 133))
    assert.same(top_before, lines.get_lines(135, 148))
  end)

  it("swaps down annotated functions of different length", function()
    vim.fn.cursor(131, 1) -- |def handler_top
    local top_before = lines.get_lines(123, 136)
    local bottom_before = lines.get_lines(138, 148)

    tw.swap_down()

    h.assert_cursor_at(143, 1)
    assert.same(bottom_before, lines.get_lines(123, 133))
    assert.same(top_before, lines.get_lines(135, 148))
  end)

  it("swaps up from a decorated/commented node to a bare one", function()
    vim.fn.cursor(131, 1) -- |def handler_top
    local top_before = lines.get_lines(118, 119)
    local bottom_before = lines.get_lines(123, 136)

    tw.swap_up()

    h.assert_cursor_at(126, 1)
    assert.same(bottom_before, lines.get_lines(118, 131))
    assert.same(top_before, lines.get_lines(135, 136))
  end)

  it("swaps down from a bare node to a decorated/commented one", function()
    vim.fn.cursor(118, 1) -- |def other
    local top_before = lines.get_lines(118, 119)
    local bottom_before = lines.get_lines(123, 136)

    tw.swap_down()

    h.assert_cursor_at(135, 1)
    assert.same(bottom_before, lines.get_lines(118, 131))
    assert.same(top_before, lines.get_lines(135, 136))
  end)
end)
