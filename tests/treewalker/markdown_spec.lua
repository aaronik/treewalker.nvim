local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("Movement in a markdown file", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  -- TODO this needs to work
  -- h.ensure_has_parser()

  -- This is hard, treesitter is showing all java code as a "block_continuation"
  -- at the same level.
  pending("respects embedded java", function()
    vim.fn.cursor(120, 1)
    tw.move_down()
    h.assert_cursor_at(126, 1)
  end)

  pending("jumps from one header to another", function()
    vim.fn.cursor(4, 1)
    tw.move_down()
    h.assert_cursor_at(19, 1, "## Text Formatting")
  end)
end)

describe("Swapping in a markdown file:", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

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
