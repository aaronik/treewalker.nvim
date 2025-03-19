local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Movement in a haskell file: ", function()
  before_each(function()
    load_fixture("/haskell.hs")
  end)

  h.ensure_has_parser()

  it("moves out of a nested node", function()
    vim.fn.cursor(22, 3)
    tw.move_out()
    h.assert_cursor_at(19, 1, "|randomList")
  end)
end)


