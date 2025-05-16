local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local strategies = require 'treewalker.strategies'
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
    h.assert_cursor_at(19, 1, "## Text Formatting")
  end)

  it("navigates out from text content to the nearest header", function()
    vim.fn.cursor(26, 1)
    tw.move_out()
    h.assert_cursor_at(19, 1, "## Text Formatting")
  end)
end)

describe("Swapping in a markdown file:", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  h.ensure_has_parser("markdown")

  it("swaps only work when on headers", function()
    -- Test from various non-header positions
    local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Test from paragraph text
    vim.fn.cursor(7, 1)
    tw.swap_up()
    local content1 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content1, "Buffer changed when swapping up from paragraph")

    tw.swap_down()
    local content2 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content2, "Buffer changed when swapping down from paragraph")

    -- Test from list item
    vim.fn.cursor(22, 1)
    tw.swap_up()
    local content3 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content3, "Buffer changed when swapping up from list item")

    tw.swap_down()
    local content4 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content4, "Buffer changed when swapping down from list item")

    -- Test from code block
    vim.fn.cursor(31, 1)
    tw.swap_up()
    local content5 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content5, "Buffer changed when swapping up from code block")

    tw.swap_down()
    local content6 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content6, "Buffer changed when swapping down from code block")

    -- Test from inline code
    vim.fn.cursor(36, 1)
    tw.swap_up()
    local content7 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content7, "Buffer changed when swapping up from inline code")

    tw.swap_down()
    local content8 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content8, "Buffer changed when swapping down from inline code")
  end)

  it("swaps h2 headers down with their content", function()
    local first = lines.get_lines(4, 17)
    local second = lines.get_lines(19, 36)
    vim.fn.cursor(4, 1)
    tw.swap_down()
    assert.same(first, lines.get_lines(23, 36))
    assert.same(second, lines.get_lines(4, 21))
  end)

  it("swaps h2 headers up with their content", function()
    local first = lines.get_lines(4, 17)
    local second = lines.get_lines(19, 36)
    vim.fn.cursor(19, 1)
    tw.swap_up()
    assert.same(first, lines.get_lines(23, 36))
    assert.same(second, lines.get_lines(4, 21))
  end)

  pending("left and right swap are disabled", function()
    -- Position on a header
    vim.fn.cursor(4, 1)

    -- Get original content
    local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Try to use left swap (should be disabled for markdown)
    tw.swap_left()
    local content_after_left = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content_after_left, "Buffer changed when using left swap on markdown")

    -- Try to use right swap (should be disabled for markdown)
    tw.swap_right()
    local content_after_right = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content_after_right, "Buffer changed when using right swap on markdown")
  end)

  pending("doesn't swap when not on header", function()
    -- Position on paragraph (non-header)
    vim.fn.cursor(7, 1)

    -- Get original content
    local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Try to swap up from non-header position
    tw.swap_up()
    local content1 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content1, "Buffer changed when swapping up from non-header")

    -- Try to swap down from non-header position
    tw.swap_down()
    local content2 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content2, "Buffer changed when swapping down from non-header")

    -- Position on code block (another non-header)
    vim.fn.cursor(30, 1)
    local original_content2 = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Try to swap from code block
    tw.swap_down()
    local content3 = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content2, content3, "Buffer changed when swapping down from code block")
  end)

  pending("doesn't break when swapping single h1", function()
    -- Position on main title (h1)
    vim.fn.cursor(1, 1)

    -- Get original content
    local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Try to swap up (should do nothing as there's no h1 above)
    tw.swap_up()
    local content_after_up = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content_after_up, "Buffer changed when swapping h1 up with no target")

    -- Try to swap down (should do nothing as there's no h1 below)
    tw.swap_down()
    local content_after_down = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same(original_content, content_after_down, "Buffer changed when swapping h1 down with no target")
  end)

  pending("doesn't swap headers of different levels", function()
    -- Get original content
    local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Position on h3 header and try to swap with h4 below
    vim.fn.cursor(41, 1) -- ### Another Header
    tw.swap_down()

    -- Position on h4 header and try to swap with h3 above
    vim.fn.cursor(43, 1) -- #### Yet Another One
    tw.swap_up()

    -- Get content after attempted swaps
    local content_after = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Verify no change occurred
    assert.same(original_content, content_after, "Headers of different levels should not be swapped")
  end)
end)
