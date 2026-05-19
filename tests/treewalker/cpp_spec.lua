local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In a C++ file:", function()
  before_each(function()
    load_fixture("/cpp.cpp")
  end)

  h.ensure_has_parser("cpp")

  it("moves around", function()
      vim.fn.cursor(6, 1) -- At namespace foo.
      tw.move_in()
      h.assert_cursor_at(8, 1) -- Should move into namespace and land at struct A.
      tw.move_down()
      h.assert_cursor_at(13, 1) -- Should move to struct B.
      tw.move_down()
      h.assert_cursor_at(18, 1) -- Should move to struct C.
      tw.move_in()
      h.assert_cursor_at(20, 5) -- Should move into struct C to double z.
      tw.move_out()
      h.assert_cursor_at(18, 1) -- Should move back out to struct C
      tw.move_down()
      h.assert_cursor_at(23, 1) -- Should move to bar function.
      tw.move_up()
      h.assert_cursor_at(18, 1) -- Should move back to struct C.
      tw.move_up()
      h.assert_cursor_at(13, 1) -- Should move back to struct B.
      tw.move_up()
      h.assert_cursor_at(8, 1) -- Should move back to struct A.
      tw.move_out()
      h.assert_cursor_at(6, 1) -- Should move back out to namespace foo
  end)
end)
