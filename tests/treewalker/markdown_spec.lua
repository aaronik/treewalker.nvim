local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("Movement in a markdown file", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  h.ensure_has_parser("markdown")

  it("jumps from one header to another at same level", function()
    vim.fn.cursor(4, 1)
    tw.move_down()
    h.assert_cursor_at(19, 1, "## Text Formatting")
    tw.move_up()
    h.assert_cursor_at(4, 1, "## Header")
  end)

  it("moves to inner headings with move_in", function()
    vim.fn.cursor(4, 1)
    tw.move_in()
    h.assert_cursor_at(9, 1, "### Subheader")
  end)

  it("moves to parent headings with move_out", function()
    vim.fn.cursor(9, 1)
    tw.move_out()
    h.assert_cursor_at(4, 1, "## Header")
  end)

  it("correctly handles h1 headings with underline style (===)", function()
    vim.fn.cursor(1, 1)
    tw.move_down()
    h.assert_cursor_at(2, 1)
    tw.move_down()
    h.assert_cursor_at(4, 1)
    tw.move_down()
    h.assert_cursor_at(19, 1)
  end)

  it("correctly handles h2 headings with underline style (---)", function()
    vim.fn.cursor(19, 1)
    tw.move_down()
    h.assert_cursor_at(38, 1)
  end)

  it("doesn't move from h1 upward", function()
    vim.fn.cursor(1, 1)
    tw.move_up()
    h.assert_cursor_at(1, 1)
  end)

  it("doesn't move outward from h1 headings", function()
    vim.fn.cursor(1, 1)
    tw.move_out()
    h.assert_cursor_at(1, 1)
  end)

  pending("stops at document boundaries when moving down", function()
    vim.fn.cursor(110, 1)
    tw.move_down()
    tw.move_down()
    tw.move_down()
    h.assert_cursor_at(110, 1)
  end)

  pending("handles no inner headings gracefully", function()
    vim.fn.cursor(14, 1)
    tw.move_in()
    h.assert_cursor_at(14, 1)
  end)
end)

describe("Swapping in a markdown file:", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  h.ensure_has_parser("markdown")

  it("turns off for down in md files", function()
    vim.fn.cursor(1, 1)
    local lines_before = lines.get_lines(0, -1)
    tw.swap_down()
    local lines_after = lines.get_lines(0, -1)
    assert.same(lines_after, lines_before)
  end)

  it("turns off for up in md files", function()
    vim.fn.cursor(3, 1)
    local lines_before = lines.get_lines(0, -1)
    tw.swap_up()
    local lines_after = lines.get_lines(0, -1)
    assert.same(lines_after, lines_before)
  end)

  it("turns off for left in md files", function()
    vim.fn.cursor(45, 1)
    local lines_before = lines.get_lines(0, -1)
    tw.swap_left()
    local lines_after = lines.get_lines(0, -1)
    assert.same(lines_after, lines_before)
  end)

  it("turns off for right in md files", function()
    vim.fn.cursor(45, 1)
    local lines_before = lines.get_lines(0, -1)
    tw.swap_right()
    local lines_after = lines.get_lines(0, -1)
    assert.same(lines_after, lines_before)
  end)
end)

