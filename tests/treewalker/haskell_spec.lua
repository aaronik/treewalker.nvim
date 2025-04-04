local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In a haskell file: ", function()
  before_each(function()
    load_fixture("/haskell.hs")
  end)

  h.ensure_has_parser("haskell")

  -- Oh dang when did this break?
  pending("moves around in a haskell file", function ()
    vim.fn.cursor(1, 1)
    tw.move_down()
    h.assert_cursor_at(2, 1)
    tw.move_down()
    h.assert_cursor_at(3, 1)
    tw.move_down()
    h.assert_cursor_at(6, 1)
    tw.move_in()
    h.assert_cursor_at(9, 3)
  end)

  it("moves out of a nested node", function()
    vim.fn.cursor(22, 3)
    tw.move_out()
    h.assert_cursor_at(19, 1)
  end)
end)


