local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'

describe("Swapping in a c file:", function()
  before_each(function()
    load_fixture("/c.c")
  end)

  it("swaps right, when cursor is inside a string, the whole string", function()
    vim.fn.cursor(14, 17) -- the o in one
    assert.same('        printf("one\\n", "two\\n");', lines.get_line(14))
    tw.swap_right()
    assert.same('        printf("two\\n", "one\\n");', lines.get_line(14))
  end)

  it("swaps left, when cursor is inside a string, the whole string", function()
    vim.fn.cursor(17, 28) -- the t in two
    assert.same('        printf("one\\n", "\\ntwo\\n");', lines.get_line(17))
    tw.swap_left()
    assert.same('        printf("\\ntwo\\n", "one\\n");', lines.get_line(17))
  end)
end)
