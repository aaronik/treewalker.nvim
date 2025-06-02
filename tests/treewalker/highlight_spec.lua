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
    tw.setup({ highlight = true, highlight_duration = 500 })
  end)

  it("creates visible highlights when moving and clears them after timeout", function()
    h.assert_highlight_count_eventually(0)
    vim.fn.cursor(10, 1)
    tw.move_down()
    h.assert_highlight_count_eventually(function(n) return n >= 1 end, 200)
    vim.wait(520, function() return false end)
    h.assert_highlight_count_eventually(0, 200)
  end)

  it("clears previous highlights when making new movement", function()
    h.assert_highlight_count_eventually(0)
    vim.fn.cursor(10, 1)
    tw.move_down()
    h.assert_highlight_count_eventually(function(n) return n >= 1 end, 200)
    tw.move_up()
    h.assert_highlight_count_eventually(function(n) return n >= 1 end, 200)
  end)

  it("does not create highlights when highlight option is disabled", function()
    tw.setup({ highlight = false })
    h.assert_highlight_count_eventually(0)
    vim.fn.cursor(10, 1)
    tw.move_down()
    tw.move_up()
    tw.move_in()
    tw.move_out()
    h.assert_highlight_count_eventually(0, 200)
  end)

  it("highlights appear when moving in any direction", function()
    h.assert_highlight_count_eventually(0)
    vim.fn.cursor(10, 1)
    tw.move_in()
    h.assert_highlight_count_eventually(function(n) return n >= 1 end, 200)
  end)

  it("highlights full block on move_in() (identified in gh #30)", function()
    vim.fn.cursor(21, 1)
    tw.move_in()
    h.assert_highlighted(22, 3, 26, 5)
  end)

  it("respects default highlight_duration", function()
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    local tw_init = require('treewalker')
    tw_init.opts = {
      highlight = true,
      highlight_duration = 250,
      highlight_group = "CursorLine",
      jumplist = true,
    }
    local highlight_stub = stub.new(operations, "highlight")
    vim.fn.cursor(10, 1)
    tw.move_down()
    assert.stub(highlight_stub).was.called(1)
    local duration_arg = highlight_stub.calls[1].refs[2]
    assert.equal(250, duration_arg)
    highlight_stub:revert()
  end)

  it("respects default highlight_group", function()
    tw.setup({ highlight = true })
    vim.fn.cursor(10, 1)
    tw.move_down()
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })
    assert.True(#highlights >= 1)
    for _, ext in ipairs(highlights) do
      assert.equal("CursorLine", ext[4].hl_group)
    end
  end)

  it("respects highlight_group config option", function()
    tw.setup({ highlight = true, highlight_group = "DiffAdd" })
    vim.fn.cursor(10, 1)
    tw.move_down()
    local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
    local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })
    assert.True(#highlights >= 1)
    for _, ext in ipairs(highlights) do
      assert.equal("DiffAdd", ext[4].hl_group)
    end
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
