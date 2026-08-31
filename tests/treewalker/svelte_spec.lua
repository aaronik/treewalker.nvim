local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In a Svelte file", function()
  before_each(function()
    load_fixture("/svelte.svelte")
  end)

  h.ensure_has_parser("svelte")
  h.ensure_has_parser("javascript")
  h.ensure_has_parser("css")

  it("moves out from embedded script to its host element", function()
    vim.fn.cursor(2, 7)
    tw.move_out()
    h.assert_cursor_at(1, 1)
  end)

  it("moves out from embedded style to its host element", function()
    vim.fn.cursor(10, 5)
    tw.move_out()
    h.assert_cursor_at(9, 1)
  end)
end)
