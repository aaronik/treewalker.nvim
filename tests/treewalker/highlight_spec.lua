local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local stub = require 'luassert.stub'
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local operations = require 'treewalker.operations'

describe("Highlights", function()
  load_fixture("/lua.lua")

  before_each(function()
    -- Clear any leftover namespaces from previous tests
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    tw.setup({ highlight = true, highlight_duration = 5 })
  end)

  it("creates visible highlights when moving and clears them after timeout", function()
    -- Start with clean state - count initial highlights
    local initial_count = h.get_highlight_count()
    assert.equal(0, initial_count)

    vim.fn.cursor(10, 1)
    tw.move_down()

    local after_move_count = h.get_highlight_count()
    assert.equal(1, after_move_count, "No OG highlight detected")

    -- Wait for timeout and verify highlights are cleared
    vim.wait(20, function() return false end)
    local after_timeout_count = h.get_highlight_count()
    assert.equal(0, after_timeout_count, "Highlights not cleared after timeout")
  end)

  it("clears previous highlights when making new movement", function()
    assert.equal(0, h.get_highlight_count())

    vim.fn.cursor(10, 1)
    tw.move_down()
    tw.move_up()

    assert.equal(1, h.get_highlight_count())
  end)

  it("does not create highlights when highlight option is disabled", function()
    tw.setup({ highlight = false })
    assert.equal(0, h.get_highlight_count())

    vim.fn.cursor(10, 1)
    tw.move_down()
    tw.move_up()
    tw.move_in()
    tw.move_out()

    assert.equal(0, h.get_highlight_count(), "Highlights created when disabled")
  end)

  it("highlights appear when moving in any direction", function()
    assert.equal(0, h.get_highlight_count())

    vim.fn.cursor(10, 1)
    tw.move_in()

    assert.equal(1, h.get_highlight_count())
  end)

  it("highlights full block on move_in() (identified in gh #30)", function()
    vim.fn.cursor(21, 1)
    tw.move_in()
    h.assert_highlighted(22, 3, 26, 5)
  end)

  it("respects default highlight_duration", function()
    -- Clear any leftover namespaces from previous tests
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    -- Directly set opts to default values to bypass before_each
    local tw_init = require('treewalker')
    tw_init.opts = {
      highlight = true,
      highlight_duration = 250,
      highlight_group = "CursorLine",
      jumplist = true,
    }

    -- Stub the highlight function to capture arguments
    local highlight_stub = stub.new(operations, "highlight")

    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Verify highlight function was called with default duration (250)
    assert.stub(highlight_stub).was.called(1)
    local duration_arg = highlight_stub.calls[1].refs[2]
    assert.equal(250, duration_arg)

    -- Restore the original function
    highlight_stub:revert()
  end)

  it("respects default highlight_group", function()
    tw.setup({ highlight = true })

    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Verify the highlight uses the default group
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })

    assert.equal(1, #highlights)
    assert.equal("CursorLine", highlights[1][4].hl_group)
  end)

  it("respects highlight_group config option", function()
    tw.setup({ highlight = true, highlight_group = "DiffAdd" })

    vim.fn.cursor(10, 1)
    tw.move_down()

    -- Verify the highlight uses the configured group
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })

    assert.equal(1, #highlights)
    assert.equal("DiffAdd", highlights[1][4].hl_group)
  end)

  it("highlights whole functions", function()
    vim.fn.cursor(10, 1)
    tw.move_down()
    h.assert_highlighted(21, 1, 28, 3)
  end)

  it("highlights whole lines starting with identifiers", function()
    vim.fn.cursor(134, 5)
    tw.move_up()
    h.assert_highlighted(133, 5, 133, 33)
  end)

  it("highlights whole lines starting with assignments", function()
    vim.fn.cursor(133, 5)
    tw.move_down()
    h.assert_highlighted(134, 5, 134, 18)
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(133, 5)
    tw.move_out()
    h.assert_highlighted(132, 3, 135, 5)
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(132, 3)
    tw.move_out()
    h.assert_highlighted(128, 1, 137, 3)
  end)

  it("doesn't highlight the whole file", function()
    vim.fn.cursor(3, 1)
    tw.move_up()
    h.assert_highlighted(1, 1, 1, 39)
  end)

  -- Note this is highly language dependent, so this test is not so powerful
  it("highlights only the first item in a block", function()
    vim.fn.cursor(27, 3)
    tw.move_up()
    h.assert_highlighted(22, 3, 26, 5)
  end)

  it("given in a line with no parent, move_out highlights the whole node", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_out()
    h.assert_cursor_at(21, 1)
    h.assert_highlighted(21, 1, 28, 3)
  end)
end)

