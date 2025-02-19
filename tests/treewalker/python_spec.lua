local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("Movement in a python file: ", function()
  before_each(function()
    load_fixture("/python.py")
  end)

  it("move_in doesn't land on non target nodes", function()
    vim.fn.cursor(54, 1)
    tw.move_in()
    h.assert_cursor_at(56, 5, "def __init__")
  end)

  it("You can get into the body of a function with multiline signature", function()
    vim.fn.cursor(131, 3) -- de|f
    tw.move_in()
    h.assert_cursor_at(132, 5)
    tw.move_down()
    h.assert_cursor_at(133, 5)
    tw.move_down()
    h.assert_cursor_at(134, 5)
    tw.move_down()
    h.assert_cursor_at(136, 5, "|print")
  end)
end)

describe("Swapping in a python file:", function()
  before_each(function()
    load_fixture("/python.py")
  end)

  it("swaps up annotated functions of different length", function()
    vim.fn.cursor(143, 1) -- |def handler_bottom
    tw.swap_up()
    h.assert_cursor_at(128, 1, "|def handler_bottom")
    assert.same('# C2', lines.get_line(123))
    assert.same('@random_annotation({', lines.get_line(124))
    assert.same('def handler_bottom(', lines.get_line(128))

    assert.same('# C1', lines.get_line(135))
    assert.same('@random_annotation({', lines.get_line(137))
    assert.same('def handler_top(', lines.get_line(143))
  end)

  it("swaps down annotated functions of different length", function()
    vim.fn.cursor(131, 1) -- |def handler_top
    tw.swap_down()
    h.assert_cursor_at(143, 1, "|def handler_top")
    assert.same('# C2', lines.get_line(123))
    assert.same('@random_annotation({', lines.get_line(124))
    assert.same('def handler_bottom(', lines.get_line(128))

    assert.same('# C1', lines.get_line(135))
    assert.same('@random_annotation({', lines.get_line(137))
    assert.same('def handler_top(', lines.get_line(143))
  end)

  it("swaps up from a decorated/commented node to a bare one", function()
    vim.fn.cursor(131, 1) -- |def handler_top
    tw.swap_up()
    assert.same('# C1', lines.get_line(118))
    assert.same('@random_annotation({', lines.get_line(120))
    assert.same('def handler_top(', lines.get_line(126))

    assert.same('def other():', lines.get_line(135))

    h.assert_cursor_at(126, 1, "|def handler_top")
  end)

  it("swaps down from a bare node to a decorated/commented one", function()
    vim.fn.cursor(118, 1) -- |def other
    tw.swap_down()
    assert.same('# C1', lines.get_line(118))
    assert.same('@random_annotation({', lines.get_line(120))
    assert.same('def handler_top(', lines.get_line(126))

    assert.same('def other():', lines.get_line(135))

    h.assert_cursor_at(135, 1, "|def other")
  end)
end)

