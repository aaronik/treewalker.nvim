local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In an html file", function()
  before_each(function()
    load_fixture("/html.html")
  end)

  h.ensure_has_parser("html")
  h.ensure_has_parser("javascript")

  it("doesn't stop on footers", function()
    vim.fn.cursor(10, 5)
    tw.move_down()
    h.assert_cursor_at(22, 5)
  end)

  it("can move_in into embedded javascript", function()
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

  it("can move_out out of embedded javascript", function()
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
end)
