local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Select", function()
  load_fixture("/lua.lua")

  before_each(function()
    -- Clear any leftover namespaces from previous tests
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    -- Exit visual mode if we're in it and wait for mode change
    if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' or vim.fn.mode() == '\22' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), 'n', false)
      vim.wait(10, function() return vim.fn.mode() == 'n' end)
    end

    -- Clear any previous visual selection marks
    vim.api.nvim_buf_set_mark(0, '<', 1, 0, {})
    vim.api.nvim_buf_set_mark(0, '>', 1, 0, {})

    tw.setup({ select = true })
  end)

  it("creates visual selection when moving and select is enabled", function()
    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Check that we're in visual mode
    local mode = vim.fn.mode()
    assert.equal("v", mode)
  end)

  it("does not create highlights when select is enabled", function()
    local initial_count = h.get_highlight_count()
    assert.equal(0, initial_count)

    vim.fn.cursor(10, 1)
    tw.move_down()

    local after_move_count = h.get_highlight_count()
    assert.equal(0, after_move_count, "Highlights should not be created when select is enabled")
  end)

  it("selects the correct range when moving up", function()
    vim.fn.cursor(30, 1)
    tw.move_up()

    h.assert_selected(21, 1, 28, 3)
    h.assert_cursor_at(21, 1)
  end)

  it("selects the correct range when moving down", function()
    vim.fn.cursor(10, 1)
    tw.move_down()

    h.assert_selected(21, 1, 28, 3)
    h.assert_cursor_at(21, 1)
  end)

  it("selects the correct range when moving in", function()
    vim.fn.cursor(21, 1)
    tw.move_in()

    h.assert_selected(22, 3, 26, 5)
    h.assert_cursor_at(22, 3)
  end)

  it("selects the correct range when moving out", function()
    vim.fn.cursor(7, 3)
    tw.move_out()

    h.assert_selected(5, 1, 8, 1)
    h.assert_cursor_at(5, 1)
  end)

  pending("does not interfere with normal highlight when select is disabled", function()
    -- Exit visual mode if we're in it
    if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' or vim.fn.mode() == '\22' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), 'n', false)
      vim.wait(10, function() return vim.fn.mode() == 'n' end)
    end

    tw.setup({ select = false, highlight = true, highlight_duration = 5 })

    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Should not be in visual mode
    local mode = vim.fn.mode()
    assert.not_equal("v", mode)

    -- Should have highlights
    local highlight_count = h.get_highlight_count()
    assert.equal(1, highlight_count)
  end)

  pending("respects both select and highlight being disabled", function()
    -- Exit visual mode if we're in it
    if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' or vim.fn.mode() == '\22' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), 'n', false)
      vim.wait(10, function() return vim.fn.mode() == 'n' end)
    end

    tw.setup({ select = false, highlight = false })

    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Should not be in visual mode
    local mode = vim.fn.mode()
    assert.not_equal("v", mode)

    -- Should not have highlights
    local highlight_count = h.get_highlight_count()
    assert.equal(0, highlight_count)
  end)
end)

