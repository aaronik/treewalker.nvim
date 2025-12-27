local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Movement in Go file with tab indentation:", function()
  before_each(function()
    load_fixture("/go.go")
    vim.opt.tabstop = 4  -- Standard Go tab width
  end)

  h.ensure_has_parser("go")

  -- This test validates the visual column fix in targets.lua
  -- Go files use tabs for indentation, which previously caused
  -- sibling navigation to fail due to byte vs visual column mismatch
  it("moves down between tab-indented var declarations (sibling nodes)", function()
    vim.fn.cursor(6, 1)  -- First var declaration: var x = 1
    tw.move_down()
    -- Should move to next sibling var, not skip or go elsewhere
    local row = vim.fn.line('.')
    assert.equals(7, row, "Should move from var x to var y (line 7)")
    tw.move_down()
    row = vim.fn.line('.')
    assert.equals(8, row, "Should move from var y to var z (line 8)")
  end)

  it("moves up between tab-indented var declarations (sibling nodes)", function()
    vim.fn.cursor(8, 1)  -- Third var declaration: var z = 3
    tw.move_up()
    local row = vim.fn.line('.')
    assert.equals(7, row, "Should move from var z to var y (line 7)")
    tw.move_up()
    row = vim.fn.line('.')
    assert.equals(6, row, "Should move from var y to var x (line 6)")
  end)

  it("moves down between tab-indented if blocks (sibling nodes)", function()
    vim.fn.cursor(10, 1)  -- First if block
    tw.move_down()
    local row = vim.fn.line('.')
    assert.equals(14, row, "Should move from first if to second if (line 14)")
  end)

  it("moves between top-level function declarations", function()
    vim.fn.cursor(5, 1)  -- func main()
    tw.move_down()
    local row = vim.fn.line('.')
    assert.equals(19, row, "Should move from main to helper (line 19)")
  end)

  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(17, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(16, 1, 'up')
    end)
  end)
end)
