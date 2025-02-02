local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local helpers = require 'tests.treewalker.helpers'

describe("Movement in a regular lua file: ", function()
  before_each(function()
    load_fixture("/lua.lua")
  end)

  it("moves up and down at the same pace", function()
    vim.fn.cursor(1, 1) -- Reset cursor
    tw.move_down()
    helpers.assert_cursor_at(3, 1)
    tw.move_down()
    helpers.assert_cursor_at(5, 1)
    tw.move_down()
    helpers.assert_cursor_at(10, 1)
    tw.move_down()
    helpers.assert_cursor_at(21, 1)
    tw.move_up()
    helpers.assert_cursor_at(10, 1)
    tw.move_up()
    helpers.assert_cursor_at(5, 1)
    tw.move_up()
    helpers.assert_cursor_at(3, 1)
    tw.move_up()
    helpers.assert_cursor_at(1, 1)
  end)

  it("doesn't consider empty lines to be outer scopes", function()
    vim.fn.cursor(85, 1)
    tw.move_down()
    helpers.assert_cursor_at(88, 3, "local")
    vim.fn.cursor(85, 1)
    tw.move_up()
    helpers.assert_cursor_at(84, 3, "end")
  end)

  it("goes into functions eagerly", function()
    vim.fn.cursor(143, 1) -- In a bigger function
    tw.move_in()
    helpers.assert_cursor_at(144, 3)
    tw.move_in()
    helpers.assert_cursor_at(147, 5)
    tw.move_in()
    helpers.assert_cursor_at(149, 7)
  end)

  it("doesn't jump into a comment", function()
    vim.fn.cursor(177, 1)
    tw.move_in()
    helpers.assert_cursor_at(179, 3, "local")
  end)

  it("goes out of functions", function()
    vim.fn.cursor(149, 7)
    tw.move_out()
    helpers.assert_cursor_at(148, 5, "if")
    tw.move_out()
    helpers.assert_cursor_at(146, 3, "while")
    tw.move_out()
    helpers.assert_cursor_at(143, 1, "function")
  end)

  -- aka doesn't error
  it("is chill when down is invoked from empty last line", function()
    helpers.feed_keys('G')
    tw.move_down()
  end)

  it("moves up from inside a function", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_up()
    helpers.assert_cursor_at(10, 1, "local TARGET_DESCENDANT_TYPES")
  end)

  it("moves down from inside a function", function()
    vim.fn.cursor(21, 16) -- |is_jump_target
    tw.move_down()
    helpers.assert_cursor_at(30, 1, "local function is_descendant_jump_target")
  end)

  it("moves to true outer node when invoked from inside a line", function()
    vim.fn.cursor(22, 28) -- |NON_
    tw.move_out()
    helpers.assert_cursor_at(21, 1)
  end)
end)

describe("Movement in a lua spec file: ", function()
  before_each(function()
    load_fixture("/lua-spec.lua")
  end)

  -- go to first describe
  local function go_to_describe()
    vim.fn.cursor(1, 1)
    for _ = 1, 6 do
      tw.move_down()
    end
    helpers.assert_cursor_at(17, 1, "describe")
  end

  -- go to first load_buf
  local function go_to_load_buf()
    go_to_describe()
    tw.move_in(); tw.move_in()
    helpers.assert_cursor_at(19, 5, "load_buf")
  end

  it("moves up and down at the same pace", function()
    go_to_load_buf()
    tw.move_down(); tw.move_down()
    helpers.assert_cursor_at(41, 5, "it")
    tw.move_up(); tw.move_up()
    helpers.assert_cursor_at(19, 5, "load_buf")
  end)

  it("always moves down at least one line", function()
    go_to_load_buf()
    tw.move_down()
    helpers.assert_cursor_at(21, 5, "it")
  end)
end)

describe("Movement in a haskell file: ", function()
  before_each(function()
    load_fixture("/haskell.hs")
  end)

  it("moves out of a nested node", function()
    vim.fn.cursor(22, 3)
    tw.move_out()
    helpers.assert_cursor_at(19, 1, "|randomList")
  end)
end)

describe("Movement in a python file: ", function()
  before_each(function()
    load_fixture("/python.py")
  end)

  it("You can get into the body of a function with multiline signature", function()
    vim.fn.cursor(131, 3) -- de|f
    tw.move_in()
    helpers.assert_cursor_at(132, 5)
    tw.move_down()
    helpers.assert_cursor_at(133, 5)
    tw.move_down()
    helpers.assert_cursor_at(134, 5)
    tw.move_down()
    helpers.assert_cursor_at(136, 5, "|print")
  end)
end)
