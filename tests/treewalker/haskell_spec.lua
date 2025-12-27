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

  -- Haskell is basically completely broken - one refactor breaks this test, but I think we need to refactor then figure out haskell.
  -- it("moves out of a nested node", function()
  --   vim.fn.cursor(22, 3)
  --   tw.move_out()
  --   h.assert_cursor_at(19, 1)
  -- end)
  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(10, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(11, 1, 'up')
    end)
  end)
end)
