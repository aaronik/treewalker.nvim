local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In an html file", function()
  before_each(function()
    load_fixture("/html.html")
  end)

  h.ensure_has_parser("html")
  h.ensure_has_parser("javascript")

  it("doesn't stop on closing tags", function()
    vim.fn.cursor(10, 5)
    tw.move_down()
    h.assert_cursor_at(22, 5)
  end)

  pending("can move_in into embedded javascript", function()
    vim.fn.cursor(53, 5)
    tw.move_in()
    h.assert_cursor_at(54, 9)
  end)

  -- TODO Although this is working manually, the test runner isn't seeing it
  pending("can move around embedded javascript", function()
    vim.fn.cursor(59, 13)
    tw.move_out()
    h.assert_cursor_at(58, 9)
    tw.move_up() tw.move_up()
    h.assert_cursor_at(55, 9)
    tw.move_in()
    h.assert_cursor_at(59, 13)
  end)

  pending("can move_out out of embedded javascript", function()
    vim.fn.cursor(55, 9)
    tw.move_out()
    h.assert_cursor_at(53, 5)
  end)

  -- This is hard to do. Currently it seems to be treating the css block as raw text.
  pending("moves correctly around embedded css", function()
    vim.fn.cursor(67, 9)
    tw.move_down()
    h.assert_cursor_at(77, 9)
    tw.move_up()
    h.assert_cursor_at(67, 9)
  end)

  pending("moves from non-sibling nested node into css node", function()
    vim.fn.cursor(63, 9)
    tw.move_down()
    h.assert_cursor_at(67, 9)
  end)
  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(15, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(15, 1, 'up')
    end)

    it("confines swap_down", function()
      h.assert_swap_confined_by_parent(15, 1, 'down')
    end)

    it("confines swap_up", function()
      h.assert_swap_confined_by_parent(15, 1, 'up')
    end)

    it("confines swap_right", function()
      h.assert_swap_confined_by_parent(15, 1, 'right')
    end)

    it("confines swap_left", function()
      h.assert_swap_confined_by_parent(15, 1, 'left')
    end)
  end)
end)
