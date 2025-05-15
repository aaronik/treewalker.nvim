local load_fixture = require("tests.load_fixture")
local assert = require("luassert")
local stub = require("luassert.stub")
local tw = require("treewalker")
local lines = require("treewalker.lines")
local h = require("tests.treewalker.helpers")

describe("Movement in a regular lua file: ", function()
  before_each(function()
    load_fixture("/lua.lua")
  end)

  h.ensure_has_parser("lua")

  it("moves up and down at the same pace", function()
    vim.fn.cursor(1, 1) -- Reset cursor
    tw.move_down()
    h.assert_cursor_at(3, 1)
    tw.move_down()
    h.assert_cursor_at(5, 1)
    tw.move_down()
    h.assert_cursor_at(10, 1)
    tw.move_down()
    h.assert_cursor_at(21, 1)
    tw.move_up()
    h.assert_cursor_at(10, 1)
    tw.move_up()
    h.assert_cursor_at(5, 1)
    tw.move_up()
    h.assert_cursor_at(3, 1)
    tw.move_up()
    h.assert_cursor_at(1, 1)
  end)

  it("doesn't consider empty lines to be outer scopes", function()
    vim.fn.cursor(85, 1)
    tw.move_down()
    h.assert_cursor_at(88, 3, "local")
    vim.fn.cursor(85, 1)
    tw.move_up()
    h.assert_cursor_at(84, 3, "end")
  end)

  it("goes into functions eagerly", function()
    vim.fn.cursor(143, 1) -- In a bigger function
    tw.move_in()
    h.assert_cursor_at(144, 3)
    tw.move_in()
    h.assert_cursor_at(147, 5)
    tw.move_in()
    h.assert_cursor_at(149, 7)
  end)

  it("doesn't jump into a comment", function()
    vim.fn.cursor(177, 1)
    tw.move_in()
    h.assert_cursor_at(179, 3, "local")
  end)

  it("goes out of functions", function()
    vim.fn.cursor(149, 7)
    tw.move_out()
    h.assert_cursor_at(148, 5, "if")
    tw.move_out()
    h.assert_cursor_at(146, 3, "while")
    tw.move_out()
    h.assert_cursor_at(143, 1, "function")
  end)

  -- aka doesn't error
  it("is chill when down is invoked from empty last line", function()
    h.feed_keys("G")
    tw.move_down()
  end)

  it("moves up from inside a function", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_up()
    h.assert_cursor_at(10, 1, "local TARGET_DESCENDANT_TYPES")
  end)

  it("moves down from inside a function", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_down()
    h.assert_cursor_at(30, 1, "local function is_descendant_jump_target")
  end)

  it("moves to true outer node when invoked from inside a line", function()
    vim.fn.cursor(22, 28) -- |NON_
    tw.move_out()
    h.assert_cursor_at(21, 1)
  end)
end)

describe("Swapping in a regular lua file:", function()
  before_each(function()
    load_fixture("/lua.lua")
    vim.o.fileencoding = "utf-8"
  end)

  it("swap down bails early if user is on empty top level line", function()
    local lines_before = lines.get_lines(0, -1)
    vim.fn.cursor(2, 1) -- empty line
    tw.swap_down()
    local lines_after = lines.get_lines(0, -1)
    h.assert_cursor_at(2, 1) -- unchanged
    assert.same(lines_after, lines_before)
  end)

  it("swap up bails early if user is on empty top level line", function()
    local lines_before = lines.get_lines(0, -1)
    vim.fn.cursor(2, 1) -- empty line
    tw.swap_up()
    local lines_after = lines.get_lines(0, -1)
    h.assert_cursor_at(2, 1) -- unchanged
    assert.same(lines_after, lines_before)
  end)

  it("swap down bails early if user is on empty line in function", function()
    local lines_before = lines.get_lines(0, -1)
    vim.fn.cursor(51, 1)
    tw.swap_down()
    local lines_after = lines.get_lines(0, -1)
    h.assert_cursor_at(51, 1) -- unchanged
    assert.same(lines_after, lines_before)
  end)

  it("swap up bails early if user is on empty line in function", function()
    local lines_before = lines.get_lines(0, -1)
    vim.fn.cursor(51, 1) -- empty line
    tw.swap_up()
    local lines_after = lines.get_lines(0, -1)
    h.assert_cursor_at(51, 1) -- unchanged
    assert.same(lines_after, lines_before)
  end)

  it("swaps down one liners without comments", function()
    vim.fn.cursor(1, 1)
    tw.swap_down()
    assert.same({
      "local M = {}",
      "",
      "local util = require('treewalker.util')",
    }, lines.get_lines(1, 3))
    h.assert_cursor_at(3, 1)
  end)

  it("swaps up one liners without comments", function()
    vim.fn.cursor(3, 1)
    tw.swap_up()
    assert.same({
      "local M = {}",
      "",
      "local util = require('treewalker.util')",
    }, lines.get_lines(1, 3))
    h.assert_cursor_at(1, 1)
  end)

  it("swaps down when one has comments", function()
    vim.fn.cursor(21, 1)
    tw.swap_down()
    assert.same("local function is_descendant_jump_target(node)", lines.get_line(19))
    assert.same("---@param node TSNode", lines.get_line(23))
    h.assert_cursor_at(25, 1)
  end)

  it("swaps up when one has comments", function()
    vim.fn.cursor(21, 1)
    tw.swap_up()
    assert.same({
      "---@param node TSNode",
      "---@return boolean",
      "local function is_jump_target(node)",
    }, lines.get_lines(10, 12))
    h.assert_cursor_at(12, 1)
  end)

  it("swaps down when both have comments", function()
    vim.fn.cursor(38, 1)
    tw.swap_down()
    assert.same({
      "---Strictly sibling, no fancy business",
      "---@param node TSNode",
      "---@return TSNode | nil",
      "local function get_prev_sibling(node)",
    }, lines.get_lines(34, 37))
    assert.same({
      "---Do the nodes have the same starting point",
      "---@param node1 TSNode",
      "---@param node2 TSNode",
      "---@return boolean",
      "local function have_same_range(node1, node2)",
    }, lines.get_lines(49, 53))
    h.assert_cursor_at(53, 1)
  end)

  it("swaps up when both have comments", function()
    vim.fn.cursor(49, 1)
    tw.swap_up()
    assert.same({
      "---Strictly sibling, no fancy business",
      "---@param node TSNode",
      "---@return TSNode | nil",
      "local function get_prev_sibling(node)",
    }, lines.get_lines(34, 37))
    assert.same({
      "---Do the nodes have the same starting point",
      "---@param node1 TSNode",
      "---@param node2 TSNode",
      "---@return boolean",
      "local function have_same_range(node1, node2)",
    }, lines.get_lines(49, 53))
    h.assert_cursor_at(37, 1)
  end)

  it("swaps right same size parameters", function()
    assert.same("local function have_same_range(node1, node2)", lines.get_line(38))
    vim.fn.cursor(38, 32)
    tw.swap_right()
    assert.same("local function have_same_range(node2, node1)", lines.get_line(38))
    h.assert_cursor_at(38, 39)
  end)

  it("swaps left same size parameters", function()
    assert.same("local function have_same_range(node1, node2)", lines.get_line(38))
    vim.fn.cursor(38, 39)
    tw.swap_left()
    assert.same("local function have_same_range(node2, node1)", lines.get_line(38))
    h.assert_cursor_at(38, 32)
  end)

  it("swaps right diff size parameters", function()
    assert.same("  return util.contains(TARGET_DESCENDANT_TYPES, node:type())", lines.get_line(31))
    vim.fn.cursor(31, 24)
    tw.swap_right()
    assert.same("  return util.contains(node:type(), TARGET_DESCENDANT_TYPES)", lines.get_line(31))
    h.assert_cursor_at(31, 37, "TARGET_DESCENDANT_TYPES")
  end)

  it("swaps left diff size parameters", function()
    assert.same("  return util.contains(TARGET_DESCENDANT_TYPES, node:type())", lines.get_line(31))
    vim.fn.cursor(31, 49)
    tw.swap_left()
    assert.same("  return util.contains(node:type(), TARGET_DESCENDANT_TYPES)", lines.get_line(31))
    h.assert_cursor_at(31, 24, "node:type()")
  end)

  it("swaps right diff number of lines", function()
    assert.same("if true then", lines.get_line(185))
    assert.same("return M", lines.get_line(193))
    vim.fn.cursor(185, 1)
    tw.swap_right()
    assert.same("return M", lines.get_line(185))
    assert.same("if true then", lines.get_line(187))
    h.assert_cursor_at(187, 1)
  end)

  it("swaps left diff number of lines", function()
    assert.same("if true then", lines.get_line(185))
    assert.same("return M", lines.get_line(193))
    vim.fn.cursor(193, 1)
    tw.swap_left()
    assert.same("return M", lines.get_line(185))
    assert.same("if true then", lines.get_line(187))
    h.assert_cursor_at(185, 1)
  end)

  it("swaps right from inside strings", function()
    vim.fn.cursor(190, 10) -- somewhere inside "hi"
    tw.swap_right()
    assert.same("  print('bye', 'hi')", lines.get_line(190))
    h.assert_cursor_at(190, 16) -- cursor stays put for feel
  end)

  it("swaps left from inside strings", function()
    vim.fn.cursor(190, 17) -- somewhere inside "bye"
    tw.swap_left()
    assert.same("  print('bye', 'hi')", lines.get_line(190))
    h.assert_cursor_at(190, 9, "block") -- cursor stays put for feel
  end)

  it("passes along encoding to apply_text_edits", function()
    vim.fn.cursor(38, 32) -- (|node1, node2)

    local apply_text_edits_stub = stub(vim.lsp.util, "apply_text_edits")

    -- Prep the file encoding
    local expected_encoding = "utf-16"
    vim.o.fileencoding = expected_encoding

    tw.swap_right()

    -- Ensure correct encoding was used
    assert.stub(apply_text_edits_stub).was.called(1)
    local actual_encoding = apply_text_edits_stub.calls[1].refs[3]
    assert.same(expected_encoding, actual_encoding)

    -- Don't pollute the other tests
    apply_text_edits_stub:revert()
  end)

  it("defaults apply_text_edits to utf-8", function()
    vim.fn.cursor(38, 32) -- (|node1, node2)

    local apply_text_edits_stub = stub(vim.lsp.util, "apply_text_edits")

    -- Prep the file encoding
    local expected_encoding = "utf-8"
    vim.o.fileencoding = ""

    tw.swap_right()

    -- Ensure correct encoding was used
    assert.stub(apply_text_edits_stub).was.called(1)
    local actual_encoding = apply_text_edits_stub.calls[1].refs[3]
    assert.same(expected_encoding, actual_encoding)

    -- Don't pollute the other tests
    apply_text_edits_stub:revert()
  end)

  -- Actually I don't think this is supposed to work. It's ambiguous what
  -- node we're on. We'd need to do the lowest coincident that is the highest string
  -- or something.
  pending("swaps right and left equally in string concatenation", function()
    vim.fn.cursor(188, 27) -- |'three'
    assert.same("  print('one' .. 'two' .. 'three')", lines.get_line(188))
    tw.swap_left()
    h.assert_cursor_at(188, 18)
    assert.same("  print('one' .. 'three' .. 'two')", lines.get_line(188))
    tw.swap_left()
    h.assert_cursor_at(188, 9)
    assert.same("  print('one' .. 'three' .. 'two')", lines.get_line(188))
    tw.swap_right()
    h.assert_cursor_at(188, 18)
    assert.same("  print('one' .. 'three' .. 'two')", lines.get_line(188))
    tw.swap_right()
    h.assert_cursor_at(188, 27)
    assert.same("  print('one' .. 'two' .. 'three')", lines.get_line(188))
  end)
end)
