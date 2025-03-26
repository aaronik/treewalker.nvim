local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("In a lua spec file: ", function()
  before_each(function()
    load_fixture("/lua-spec.lua")
  end)

  h.ensure_has_parser("lua")

  -- go to first describe
  local function go_to_describe()
    vim.fn.cursor(1, 1)
    for _ = 1, 6 do
      tw.move_down()
    end
    h.assert_cursor_at(17, 1, "describe")
  end

  -- go to first load_buf
  local function go_to_load_buf()
    go_to_describe()
    tw.move_in(); tw.move_in()
    h.assert_cursor_at(19, 5, "load_buf")
  end

  it("moves up and down at the same pace", function()
    go_to_load_buf()
    tw.move_down(); tw.move_down()
    h.assert_cursor_at(41, 5, "it")
    tw.move_up(); tw.move_up()
    h.assert_cursor_at(19, 5, "load_buf")
  end)

  it("always moves down at least one line", function()
    go_to_load_buf()
    tw.move_down()
    h.assert_cursor_at(21, 5, "it")
  end)

  it("swaps strings right in a list", function()
    vim.fn.cursor(102, 6) -- "|k"
    assert.same('  { "k", "<CMD>Treewalker SwapUp<CR>", { desc = "up" } },', lines.get_line(102))
    tw.swap_right()
    assert.same('  { "<CMD>Treewalker SwapUp<CR>", "k", { desc = "up" } },', lines.get_line(102))
  end)

  it("swaps strings left in a list", function()
    vim.fn.cursor(102, 12) -- "<|CMD>
    assert.same('  { "k", "<CMD>Treewalker SwapUp<CR>", { desc = "up" } },', lines.get_line(102))
    tw.swap_left()
    assert.same('  { "<CMD>Treewalker SwapUp<CR>", "k", { desc = "up" } },', lines.get_line(102))
  end)

  it("follows right swaps across rows (like in these it args)", function()
    vim.fn.cursor(21, 13)
    tw.swap_right()
    assert.same('    it(function()', lines.get_line(21))
    assert.same('    end, "moves up and down at the same pace")', lines.get_line(39))
    h.assert_cursor_at(39, 10)
  end)

  it("follows left swaps across rows (like in these it args)", function()
    vim.fn.cursor(50, 13) -- go|es
    tw.swap_left()
    assert.same('    it("goes into functions eagerly", function()', lines.get_line(41))
    assert.same('    end)', lines.get_line(50))
    h.assert_cursor_at(41, 8)
  end)

  it("swaps it blocks down", function()
    assert.same('    it("one", function()', lines.get_line(67))
    assert.same('    it("two", function()', lines.get_line(87))
    vim.fn.cursor(67, 5) -- |it "one"
    tw.swap_down()
    assert.same('    it("two", function()', lines.get_line(67))
    assert.same('    it("one", function()', lines.get_line(77))
    h.assert_cursor_at(77, 5)
  end)

  it("swaps it blocks up", function()
    assert.same('    it("one", function()', lines.get_line(67))
    assert.same('    it("two", function()', lines.get_line(87))
    vim.fn.cursor(87, 5) --|it "two"
    tw.swap_up()
    assert.same('    it("two", function()', lines.get_line(67))
    assert.same('    it("one", function()', lines.get_line(77))
    h.assert_cursor_at(67, 5)
  end)

end)

