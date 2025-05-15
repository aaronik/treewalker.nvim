local load_fixture = require("tests.load_fixture")
local stub = require("luassert.stub")
local assert = require("luassert")
local tw = require("treewalker")
local h = require("tests.treewalker.helpers")
local operations = require("treewalker.operations")

local highlight_stub = stub(operations, "highlight")

-- use with rows as they're numbered in vim lines (1-indexed)
local function assert_highlighted(srow, scol, erow, ecol, desc)
  assert(highlight_stub.calls[1], "highlight was not called at all")
  assert.same({ srow - 1, scol - 1, erow - 1, ecol }, highlight_stub.calls[1].refs[1], "highlight wrong for: " .. desc)
end

describe("Highlights in a lua spec file: ", function()
  load_fixture("/lua-spec.lua")

  before_each(function()
    highlight_stub = stub(operations, "highlight")
  end)

  it("highlights full block on move_in() (identified in gh #30)", function()
    vim.fn.cursor(64, 3)
    tw.move_in()
    assert_highlighted(67, 5, 85, 8, "it block")
  end)
end)

describe("Highlights in a regular lua file: ", function()
  load_fixture("/lua.lua")

  before_each(function()
    highlight_stub = stub(operations, "highlight")
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
    highlight_stub = stub(operations, "highlight")
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
    assert_highlighted(21, 1, 28, 3, "is_jump_target function")
  end)

  it("highlights whole lines starting with identifiers", function()
    vim.fn.cursor(134, 5)
    tw.move_up()
    assert_highlighted(133, 5, 133, 33, "table.insert call")
  end)

  it("highlights whole lines starting with assignments", function()
    vim.fn.cursor(133, 5)
    tw.move_down()
    assert_highlighted(134, 5, 134, 18, "child = iter()")
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(133, 5)
    tw.move_out()
    assert_highlighted(132, 3, 135, 5, "while child")
  end)

  it("highlights out reliably", function()
    vim.fn.cursor(132, 3)
    tw.move_out()
    assert_highlighted(128, 1, 137, 3, "local f get_children")
  end)

  it("doesn't highlight the whole file", function()
    vim.fn.cursor(3, 1)
    tw.move_up()
    assert_highlighted(1, 1, 1, 39, "first line")
  end)

  -- Note this is highly language dependent, so this test is not so powerful
  it("highlights only the first item in a block", function()
    vim.fn.cursor(27, 3)
    tw.move_up()
    assert_highlighted(22, 3, 26, 5, "for _")
  end)

  it("given in a line with no parent, move_out highlights the whole node", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_out()
    h.assert_cursor_at(21, 1)
    assert_highlighted(21, 1, 28, 3, "is_jump_target function")
  end)
end)
