local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local helpers = require 'tests.treewalker.helpers'

describe("Swapping in a regular lua file: ", function()
  before_each(function ()
    load_fixture("/lua.lua")
  end)

  it("swaps down one liners without comments", function()
    vim.fn.cursor(1, 1)
    tw.swap_down()
    assert.same({ "local M = {}", "", "local util = require('treewalker.util')" }, lines.get_lines(1, 3))
    helpers.assert_cursor_at(3, 1)
  end)

  it("swaps up one liners without comments", function()
    vim.fn.cursor(3, 1)
    tw.swap_up()
    assert.same({ "local M = {}", "", "local util = require('treewalker.util')" }, lines.get_lines(1, 3))
    helpers.assert_cursor_at(1, 1)
  end)
end)
