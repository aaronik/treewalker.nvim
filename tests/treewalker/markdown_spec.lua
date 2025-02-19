local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Movement in a markdown file", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  -- This is hard, treesitter is showing all java code as a "block_continuation"
  -- at the same level.
  pending("respects embedded java", function()
    vim.fn.cursor(120, 1)
    tw.move_down()
    h.assert_cursor_at(126, 1)
  end)

  pending("jumps from one header to another", function()
    vim.fn.cursor(4, 1)
    tw.move_down()
    h.assert_cursor_at(19, 1, "## Text Formatting")
  end)

end)
