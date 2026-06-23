local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("In a bash file: ", function()
  before_each(function()
    load_fixture("/bash.sh")
  end)

  h.ensure_has_parser("bash")

  it("moves into a function body", function()
    vim.fn.cursor(4, 1) -- |greet()
    tw.move_in()
    h.assert_cursor_at(5, 3)
    tw.move_down()
    h.assert_cursor_at(6, 3)
  end)

  it("swaps functions", function()
    vim.fn.cursor(4, 1) -- |greet()

    local lines = require('treewalker.lines')
    local before_top = lines.get_lines(3, 7)
    local before_bottom = lines.get_lines(9, 11)

    tw.swap_down()

    h.assert_cursor_at(8, 1)
    assert.same(before_bottom, lines.get_lines(3, 5))
    assert.same(before_top, lines.get_lines(7, 11))
    assert.same({
      "#!/usr/bin/env bash",
      "",
      "main() {",
      "  greet",
      "}",
      "",
      "# Simple functions for tree-sitter navigation tests",
      "greet() {",
      "  echo \"hi\"",
      "  echo \"bye\"",
      "}",
      "",
      "main",
    }, lines.get_lines(1, 13))
  end)
end)
