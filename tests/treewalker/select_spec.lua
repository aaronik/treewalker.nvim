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

  it("selects the correct range when moving down", function()
    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Check that we're in visual mode and get the selection bounds
    local mode = vim.fn.mode()
    assert.equal("v", mode)

    local current_pos = vim.fn.getpos('.')
    local other_end_pos = vim.fn.getpos('v')

    -- Determine which is start and which is end
    local start_pos, end_pos
    if current_pos[2] < other_end_pos[2] or 
       (current_pos[2] == other_end_pos[2] and current_pos[3] < other_end_pos[3]) then
      start_pos, end_pos = current_pos, other_end_pos
    else
      start_pos, end_pos = other_end_pos, current_pos
    end

    -- Expected range: { 20, 0, 27, 3 } (0-indexed) = { 21, 1, 28, 3 } (1-indexed)
    assert.equal(21, start_pos[2])
    assert.equal(1, start_pos[3])
    assert.equal(28, end_pos[2])
    assert.equal(3, end_pos[3])
  end)

  it("selects the correct range when moving in", function()
    vim.fn.cursor(21, 1)
    tw.move_in()

    -- Check that we're in visual mode and get the selection bounds
    local mode = vim.fn.mode()
    assert.equal("v", mode)

    local current_pos = vim.fn.getpos('.')
    local other_end_pos = vim.fn.getpos('v')

    -- Determine which is start and which is end
    local start_pos, end_pos
    if current_pos[2] < other_end_pos[2] or 
       (current_pos[2] == other_end_pos[2] and current_pos[3] < other_end_pos[3]) then
      start_pos, end_pos = current_pos, other_end_pos
    else
      start_pos, end_pos = other_end_pos, current_pos
    end

    -- Based on debug output: { 21, 2, 25, 5 } (0-indexed) = { 22, 3, 26, 5 } (1-indexed)
    assert.equal(22, start_pos[2])
    assert.equal(3, start_pos[3])
    assert.equal(26, end_pos[2])
    assert.equal(5, end_pos[3])
  end)

  it("works with all movement directions", function()
    -- Test move_up
    vim.fn.cursor(10, 1)
    tw.move_up()
    assert.equal("v", vim.fn.mode())

    -- Exit visual mode and wait for mode change
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), 'n', false)
    vim.wait(10, function() return vim.fn.mode() == 'n' end)

    -- Test move_out
    vim.fn.cursor(133, 5)
    tw.move_out()
    assert.equal("v", vim.fn.mode())
  end)

  it("does not interfere with normal highlight when select is disabled", function()
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

  it("respects both select and highlight being disabled", function()
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