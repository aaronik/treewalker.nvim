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
    h.assert_cursor_at(1, 1)
    tw.move_in()
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

  it("stops at document boundaries when moving down", function()
    vim.fn.cursor(110, 1)
    tw.move_down()
    tw.move_down()
    tw.move_down()
    h.assert_cursor_at(110, 1)
  end)

  it("handles no inner headings gracefully", function()
    vim.fn.cursor(14, 1)
    tw.move_in()
    h.assert_cursor_at(14, 1)
  end)

  it("navigates up from text content to the nearest header", function()
    vim.fn.cursor(26, 1)
    tw.move_up()
    h.assert_cursor_at(19, 1)
  end)

  it("navigates down from text content to the nearest header", function()
    vim.fn.cursor(26, 1)
    tw.move_down()
    h.assert_cursor_at(38, 1)
  end)

  it("navigates out from text content to the nearest header", function()
    vim.fn.cursor(26, 1)
    tw.move_out()
    h.assert_cursor_at(19, 1)
  end)

  it("Moves up to same level node the same way it moves down", function()
    vim.fn.cursor(41, 1)
    tw.move_up()
    h.assert_cursor_at(9, 1)
  end)

  it("Moves down to same level node the same way it moves up", function()
    vim.fn.cursor(9, 1)
    tw.move_down()
    h.assert_cursor_at(41, 1)
  end)

  it("Disables move in when not on header", function()
    vim.fn.cursor(28, 1)
    tw.move_in()
    h.assert_cursor_at(28, 1)
  end)

  it("navigates between nested headers of different levels", function()
    vim.fn.cursor(4, 1)
    tw.move_in()
    h.assert_cursor_at(9, 1, "### Subheader")
    tw.move_in()
    h.assert_cursor_at(14, 1, "#### Tertiary Header")
    tw.move_out()
    h.assert_cursor_at(9, 1, "### Subheader")
    tw.move_out()
    h.assert_cursor_at(4, 1, "## Header")
  end)

  it("handles navigation through document sections with various content types", function()
    vim.fn.cursor(19, 1)
    tw.move_down()
    h.assert_cursor_at(38, 1, "## Headers Again")
    tw.move_down()
    h.assert_cursor_at(47, 1, "## Table")
    tw.move_down()
    h.assert_cursor_at(55, 1, "## Details")
    tw.move_down()
    h.assert_cursor_at(63, 1, "## Links")
  end)

  it("handles headings that are out of order", function()
    vim.fn.cursor(68, 1) -- ## Out of order headings

    -- navs between h2s, doesn't somehow get sucked into weird ordered content
    tw.move_down()
    h.assert_cursor_at(79, 1)
    tw.move_up()
    h.assert_cursor_at(68, 1)

    -- Goes in from h2 to h3, skipping h4
    tw.move_in()
    h.assert_cursor_at(73, 1)

    tw.move_in()
    h.assert_cursor_at(75, 1)

    tw.move_out()
    h.assert_cursor_at(73, 1)

    tw.move_out()
    h.assert_cursor_at(68, 1)
  end)

  it("navigates between headers across different content blocks", function()
    vim.fn.cursor(63, 1)
    tw.move_down()
    h.assert_cursor_at(68, 1, "## Footnotes")
    tw.move_down()
    tw.move_down()
    h.assert_cursor_at(92, 1, "## Images")
    tw.move_up()
    h.assert_cursor_at(79, 1, "## References")
  end)

  it("moves out from content to the correct heading level", function()
    vim.fn.cursor(31, 1)
    tw.move_out()
    h.assert_cursor_at(19, 1, "## Text Formatting")
    vim.fn.cursor(108, 1)
    tw.move_out()
    h.assert_cursor_at(104, 1, "## Task List")
  end)

  it("highlights whole h2", function()
    vim.fn.cursor(19, 1)
    tw.move_up()
    h.assert_highlighted(4, 1, 18, 0)
    tw.move_down()
    h.assert_highlighted(19, 1, 37, 0)
    tw.move_down()
    h.assert_highlighted(38, 1, 46, 0)
    tw.move_down()
    h.assert_highlighted(47, 1, 54, 0)
    tw.move_down()
    h.assert_highlighted(55, 1, 62, 0)
    tw.move_down()
    h.assert_highlighted(63, 1, 67, 0)
    tw.move_down()
    h.assert_highlighted(68, 1, 78, 0)
    tw.move_down()
    h.assert_highlighted(79, 1, 91, 0)
    tw.move_down()
    h.assert_highlighted(92, 1, 103, 0)
    tw.move_down()
    h.assert_highlighted(104, 1, 109, 0)
    tw.move_down()
    h.assert_highlighted(110, 1, 132, 0)
  end)
end)

describe("Swapping in a markdown file:", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  h.ensure_has_parser("markdown")

  it("swaps only work when on headers", function()
    -- Test from various non-header positions
    local original_content = lines.get_lines(0, -1)

    -- Test from paragraph text
    vim.fn.cursor(7, 1)
    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))

    -- Test from list item
    vim.fn.cursor(22, 1)
    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))

    -- Test from code block
    vim.fn.cursor(31, 1)
    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))

    -- Test from inline code
    vim.fn.cursor(36, 1)
    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))
  end)

  it("swaps h2 headers down with their content", function()
    local first = lines.get_lines(4, 17)
    local second = lines.get_lines(19, 36)
    vim.fn.cursor(4, 1)
    tw.swap_down()
    assert.same(first, lines.get_lines(23, 36))
    assert.same(second, lines.get_lines(4, 21))
    h.assert_cursor_at(23, 1)
  end)

  it("swaps h2 headers up with their content", function()
    local first = lines.get_lines(4, 17)
    local second = lines.get_lines(19, 36)
    vim.fn.cursor(19, 1)
    tw.swap_up()
    assert.same(first, lines.get_lines(23, 36))
    assert.same(second, lines.get_lines(4, 21))
    h.assert_cursor_at(4, 1)
  end)

  it("left and right swap are disabled", function()
    -- Lines to test cursor positions on
    local test_lines = { 4, 5, 10, 20, 30, 40, 50 }

    for _, line_num in ipairs(test_lines) do
      vim.fn.cursor(line_num, 1)
      local original_content = lines.get_lines(0, -1)

      tw.swap_left()
      assert.same(original_content, lines.get_lines(0, -1))

      tw.swap_right()
      assert.same(original_content, lines.get_lines(0, -1))
    end
  end)

  it("doesn't swap when not on header", function()
    vim.fn.cursor(7, 1)
    local original_content = lines.get_lines(0, -1)

    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))

    vim.fn.cursor(30, 1)
    assert.same(original_content, lines.get_lines(0, -1))

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))
  end)

  it("doesn't break when swapping single h1", function()
    vim.fn.cursor(1, 1)
    local original_content = lines.get_lines(0, -1)
    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))

    -- Try to swap down (test requires there's no second h1)
    vim.fn.cursor(1, 1)
    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))
  end)

  it("doesn't swap headers of different levels", function()
    local original_content = lines.get_lines(0, -1)
    vim.fn.cursor(41, 1)

    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))
    h.assert_cursor_at(41, 1)

    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))
    h.assert_cursor_at(41, 1)
  end)

  it("doesn't swap headers outside of their parent blocks", function()
    local original_content = lines.get_lines(0, -1)
    vim.fn.cursor(14, 1)

    tw.swap_down()
    assert.same(original_content, lines.get_lines(0, -1))
    h.assert_cursor_at(14, 1)

    tw.swap_up()
    assert.same(original_content, lines.get_lines(0, -1))
    h.assert_cursor_at(14, 1)
  end)
end)

describe("Swapping in a markdown file with h2s at the top:", function()
  before_each(function()
    load_fixture("/markdown-h2s.md")
  end)

  h.ensure_has_parser("markdown")

  it("swaps h2s even when they're at the top of the file (#40)", function()
    local first = lines.get_lines(1, 4)
    local second = lines.get_lines(6, 9)
    vim.fn.cursor(1, 1)

    tw.swap_down()

    assert.same(second, lines.get_lines(1, 4))
    assert.same(first, lines.get_lines(6, 9))
  end)
end)
