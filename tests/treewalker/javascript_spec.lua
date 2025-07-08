local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Swapping in a typescript file:", function()
  before_each(function()
    load_fixture("/javascript.js")
  end)

  h.ensure_has_parser("javascript")

  it("selects the correct range when moving out from inside something with a callback", function()
    tw.setup({ select = true })
    vim.fn.cursor(49, 7)
    tw.move_out()
    h.assert_selected(48, 5, 51, 5)
    h.assert_cursor_at(48, 5)
  end)
end)
