local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("In a typescript file:", function()
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

  it("Moves down from an indented comment block", function()
    -- Test from beginning of comment line
    vim.fn.cursor(115, 1)
    tw.move_down()
    h.assert_cursor_at(117, 1)

    -- Test from start of comment text indentation
    vim.fn.cursor(115, 3)
    tw.move_down()
    h.assert_cursor_at(117, 1)

    -- Test from within comment text - use multiple attempts for CI stability
    vim.fn.cursor(115, 7)
    tw.move_down()
    h.assert_cursor_at(117, 1)
  end)

  it("Moves down from inside a comment", function()
    -- From middle of comment text
    vim.fn.cursor(115, 10) -- Inside "whats blah blah"
    tw.move_down()
    h.assert_cursor_at(117, 1)

    -- From end of comment text
    vim.fn.cursor(115, 18) -- At end of "whats blah blah"
    tw.move_down()
    h.assert_cursor_at(117, 1)
  end)

  it("Moves down from the start of a comment", function()
    -- From the comment opener "/**"
    vim.fn.cursor(114, 1) -- At "/**"
    tw.move_down()
    h.assert_cursor_at(117, 1) -- This should consistently work

    vim.fn.cursor(114, 2) -- At "*" in "/**"
    tw.move_down()
    h.assert_cursor_at(117, 1)

    vim.fn.cursor(114, 3) -- At second "*" in "/**"
    tw.move_down()
    h.assert_cursor_at(117, 1)

    -- From the comment closer "*/"
    vim.fn.cursor(116, 1) -- At "*/"
    tw.move_down()
    h.assert_cursor_at(117, 1) -- This should consistently work

    vim.fn.cursor(116, 2) -- At "/" in "*/"
    tw.move_down()
    h.assert_cursor_at(117, 1)
  end)

  it("Moves down from Ok class comment to constructor", function()
    -- From the comment opener "/**" - stays in place
    vim.fn.cursor(121, 3) -- At "/**"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(121, 4) -- At "*" in "/**"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(121, 5) -- At second "*" in "/**"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    -- From inside comment text - moves to constructor
    vim.fn.cursor(122, 3) -- At beginning of comment line
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(122, 5) -- At start of comment text indentation
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(122, 9) -- Within "whats blah blah"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(122, 12) -- Inside "whats blah blah"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(122, 21) -- At end of "whats blah blah"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    -- From the comment closer "*/" - moves to constructor
    vim.fn.cursor(123, 3) -- At "*/"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(123, 4) -- At "*" in "*/"
    tw.move_down()
    h.assert_cursor_at(124, 3)

    vim.fn.cursor(123, 5) -- At "/" in "*/"
    tw.move_down()
    h.assert_cursor_at(124, 3)
  end)


  it("Moves out from Ok class comment to class declaration", function()
    vim.fn.cursor(121, 3) -- At "/**"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(121, 4) -- At "*" in "/**"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(121, 5) -- At second "*" in "/**"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    -- From inside comment text
    vim.fn.cursor(122, 1) -- At beginning of comment line
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(122, 3) -- At start of comment text indentation
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(122, 7) -- Within "whats blah blah"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(122, 10) -- Inside "whats blah blah"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(122, 18) -- At end of "whats blah blah"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    -- From the comment closer "*/"
    vim.fn.cursor(123, 1) -- At "*/"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(123, 2) -- At "*" in "*/"
    tw.move_out()
    h.assert_cursor_at(119, 1)

    vim.fn.cursor(123, 3) -- At "/" in "*/"
    tw.move_out()
    h.assert_cursor_at(119, 1)
  end)
end)
