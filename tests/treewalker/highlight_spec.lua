local spy = require('luassert.spy')
local match = require('luassert.match')
local load_fixture = require "tests.load_fixture"
local stub = require 'luassert.stub'
local assert = require "luassert"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local operations = require 'treewalker.operations'

-- Test for highlight clear-before-highlight behavior
describe("Clears previous highlights before applying new", function()
  local clear_spy, hlrange_spy

  before_each(function()
    clear_spy = spy.on(vim.api, "nvim_buf_clear_namespace")
    hlrange_spy = spy.on(vim.hl, "range")
  end)

  after_each(function()
    clear_spy:revert()
    hlrange_spy:revert()
  end)

  it("calls clear_namespace before every highlight", function()
    local range1 = { 1, 2, 3, 4 }
    local range2 = { 10, 2, 12, 4 }
    operations.highlight(range1, 50, "CursorLine")
    operations.highlight(range2, 50, "CursorLine")

    -- For each highlight call, we should first clear, then range highlight
    assert.spy(clear_spy).was.called_with(0, match.is_number(), 0, -1)
    assert.spy(clear_spy).was.called(2)
    assert.spy(hlrange_spy).was.called(2)
    -- check arguments
    local call1 = hlrange_spy.calls[1].vals
    local call2 = hlrange_spy.calls[2].vals
    assert.equal(0, call1[1])
    assert.is_number(call1[2])
    assert.equal("CursorLine", call1[3])
    assert.same({1,2}, call1[4])
    assert.same({3,4}, call1[5])
    assert.same({ inclusive = true }, call1[6])

    assert.equal(0, call2[1])
    assert.is_number(call2[2])
    assert.equal("CursorLine", call2[3])
    assert.same({10,2}, call2[4])
    assert.same({12,4}, call2[5])
    assert.same({ inclusive = true }, call2[6])
  end)
end)

describe("Highlights in a lua spec file: ", function()
  local highlight_stub

  load_fixture("/lua-spec.lua")

  before_each(function()
    highlight_stub = stub.new(operations, "highlight")
  end)

  after_each(function()
    highlight_stub:revert()
  end)

  it("highlights full block on move_in() (identified in gh #30)", function()
    vim.fn.cursor(64, 3)
    tw.move_in()
    h.assert_highlighted(67, 5, 85, 8, highlight_stub, "it block")
  end)
end)

describe("Highlights in a regular lua file: ", function()
  local highlight_stub

  load_fixture("/lua.lua")

  before_each(function()
    highlight_stub = stub.new(operations, "highlight")
  end)

  after_each(function()
    highlight_stub:revert()
  end)

  it("respects default highlight option", function()
    tw.setup() -- highlight defaults to true, doesn't blow up with empty setup
    vim.fn.cursor(23, 5)
    tw.move_out()
    tw.move_down()
    tw.move_up()
    tw.move_in()
    assert.equal(4, #highlight_stub.calls)
  end)

  it("respects highlight config option", function()
    highlight_stub = stub.new(operations, "highlight")
    tw.setup({ highlight = false })
    vim.fn.cursor(23, 5)
    tw.move_out()
    tw.move_down()
    tw.move_up()
    tw.move_in()
    assert.equal(0, #highlight_stub.calls)

    highlight_stub = stub(operations, "highlight")
    tw.setup({ highlight = true })
    vim.fn.cursor(23, 5)
    tw.move_out()
    tw.move_down()
    tw.move_up()
    tw.move_in()
    assert.equal(4, #highlight_stub.calls)
  end)

  it("respects default highlight_duration", function()
    tw.setup({ highlight = true })
    tw.move_out()
    local duration_arg = highlight_stub.calls[1].refs[2]
    assert.equal(250, duration_arg)
  end)

  it("respects highlight_duration config option", function()
    local duration = 50
    tw.setup({ highlight = true, highlight_duration = duration })
    tw.move_out()
    tw.move_down()
    tw.move_up()
    tw.move_in()
    assert.stub(highlight_stub).was.called(4)
    local duration_arg = highlight_stub.calls[1].refs[2]
    assert.equal(duration, duration_arg)
  end)

  it("respects default highlight_group", function()
    tw.setup({ highlight = true, highlight_duration = 250 })
    tw.move_down()
    local hl_group_arg = highlight_stub.calls[1].refs[3]
    assert.equal("CursorLine", hl_group_arg)
  end)

  it("respects highlight_group config option", function()
    tw.setup({ highlight = true, highlight_duration = 50, highlight_group = "DiffAdd" })
    tw.move_down()
    local hl_group_arg = highlight_stub.calls[1].refs[3]
    assert.equal("DiffAdd", hl_group_arg)
  end)

  it("highlights whole functions", function()
    vim.fn.cursor(10, 1)
    tw.move_down()
    h.assert_highlighted(21, 1, 28, 3, highlight_stub, "is_jump_target function")
  end)

  it("highlights whole lines starting with identifiers", function()
    vim.fn.cursor(134, 5)
    tw.move_up()
    h.assert_highlighted(133, 5, 133, 33, highlight_stub, "table.insert call")
  end)

  it("highlights whole lines starting with assignments", function()
    vim.fn.cursor(133, 5)
    tw.move_down()
    h.assert_highlighted(134, 5, 134, 18, highlight_stub, "child = iter()")
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(133, 5)
    tw.move_out()
    h.assert_highlighted(132, 3, 135, 5, highlight_stub, "while child")
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(132, 3)
    tw.move_out()
    h.assert_highlighted(128, 1, 137, 3, highlight_stub, "local f get_children")
  end)

  it("doesn't highlight the whole file", function()
    vim.fn.cursor(3, 1)
    tw.move_up()
    h.assert_highlighted(1, 1, 1, 39, highlight_stub, "first line")
  end)

  -- Note this is highly language dependent, so this test is not so powerful
  it("highlights only the first item in a block", function()
    vim.fn.cursor(27, 3)
    tw.move_up()
    h.assert_highlighted(22, 3, 26, 5, highlight_stub, "for _")
  end)

  it("given in a line with no parent, move_out highlights the whole node", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_out()
    h.assert_cursor_at(21, 1)
    h.assert_highlighted(21, 1, 28, 3, highlight_stub, "is_jump_target function")
  end)
end)

