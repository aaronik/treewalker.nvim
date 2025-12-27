local load_fixture = require "tests.load_fixture"
local h = require 'tests.treewalker.helpers'
local tw = require 'treewalker'

describe("In a scheme file:", function()
  before_each(function()
    load_fixture("/scheme.scm")
  end)

  h.ensure_has_parser("scheme")

  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(13, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(13, 1, 'up')
    end)

    it("confines swap_down", function()
      h.assert_swap_confined_by_parent(13, 1, 'down')
    end)

    it("confines swap_up", function()
      h.assert_swap_confined_by_parent(13, 1, 'up')
    end)

    it("confines swap_right", function()
      h.assert_swap_confined_by_parent(13, 1, 'right')
    end)

    it("confines swap_left", function()
      h.assert_swap_confined_by_parent(13, 1, 'left')
    end)
  end)
end)
