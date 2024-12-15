local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local helpers = require 'tests.treewalker.helpers'

-- Feed keys to neovim; keys are pressed no matter what vim mode or state
---@param keys string
---@return nil
local function feed_keys(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, true, true)
  vim.api.nvim_feedkeys(termcodes, 'mtx', false)
end

describe("Movement in a regular lua file: ", function()
  load_fixture("/lua.lua")

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

  it("adds to jumplist", function()
    vim.cmd('windo clearjumps')
    vim.fn.cursor(1, 1)
    tw.move_down()
    helpers.assert_cursor_at(3, 1)
    feed_keys('<C-o>')
    helpers.assert_cursor_at(1, 1, "local M = {}")

    vim.cmd('windo clearjumps')
    vim.fn.cursor(21, 1)
    tw.move_in(); tw.move_in()
    helpers.assert_cursor_at(23, 5, "if node:type")
    feed_keys('<C-o>')
    helpers.assert_cursor_at(22, 3, "for _,")
    feed_keys('<C-o>')
    helpers.assert_cursor_at(21, 1, "local function is_jump_target")
  end)
end)

describe("Movement in a lua spec file: ", function()
  load_fixture("/lua-spec.lua")

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

  it("down moves at least one line", function()
    go_to_load_buf()
    tw.move_down()
    helpers.assert_cursor_at(21, 5, "it")
  end)
end)
