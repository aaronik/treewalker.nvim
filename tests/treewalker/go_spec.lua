local load_fixture = require "tests.load_fixture"
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'
local lines = require 'treewalker.lines'

local trailing_comment = " // swap any node from here to left multiple times, it will go and replace the entire line "
  .. "with the above line, it will do the same with swap to righ and swap the below line"

describe("Movement in Go file with tab indentation:", function()
  before_each(function()
    load_fixture("/go.go")
    vim.opt.tabstop = 4  -- Standard Go tab width
  end)

  h.ensure_has_parser("go")

  -- This test validates the visual column handling in anchor.lua
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

  it("skips switch cases with move_down", function()
    vim.fn.cursor(28, 1) -- switch i
    tw.move_down()
    h.assert_cursor_at(38, 2, 'fmt.Println("done")')
  end)

  it("skips switch cases with move_up", function()
    vim.fn.cursor(38, 1) -- fmt.Println("done")
    tw.move_up()
    h.assert_cursor_at(28, 2, "switch i { //")
  end)

  it("moves out of a switch case to its switch", function()
    vim.fn.cursor(29, 1) -- case 1
    tw.move_out()
    h.assert_cursor_at(28, 2, "switch i { //")
  end)

  it("moves between switch cases", function()
    vim.fn.cursor(29, 1) -- case 1
    tw.move_down()
    h.assert_cursor_at(33, 2, "case 2:")
  end)

  it("swaps a range blank identifier right", function()
    vim.fn.cursor(43, 6) -- |_|, num := range nums

    tw.swap_right()

    assert.same("\tfor num, _ := range nums {", lines.get_line(43))
  end)

  it("does not swap a range clause with a loop body", function()
    vim.fn.cursor(43, 7) -- _, |num := range nums

    tw.swap_right()

    assert.same("\tfor _, num := range nums {", lines.get_line(43))
  end)

  it("swaps a call left from its first identifier in a return list", function()
    vim.fn.cursor(50, 12) -- return 2, |fmt.Errorf("error")

    tw.swap_left()

    assert.same('\treturn fmt.Errorf("error"), 2', lines.get_line(50))
  end)

  it("swaps a call right from its first identifier in a return list", function()
    vim.fn.cursor(54, 9) -- return |fmt.Errorf("error"), 2

    tw.swap_right()

    assert.same('\treturn 2, fmt.Errorf("error")', lines.get_line(54))
  end)

  it("swaps a return call right from its method name", function()
    vim.fn.cursor(54, 13) -- return fmt.|Errorf("error"), 2

    tw.swap_right()

    assert.same('\treturn 2, fmt.Errorf("error")', lines.get_line(54))
  end)

  it("swaps a return call right from inside its string argument", function()
    vim.fn.cursor(54, 22) -- return fmt.Errorf("|error"), 2

    tw.swap_right()

    assert.same('\treturn 2, fmt.Errorf("error")', lines.get_line(54))
  end)

  it("swaps a return call left from inside its string argument", function()
    vim.fn.cursor(50, 25) -- return 2, fmt.Errorf("|error")

    tw.swap_left()

    assert.same('\treturn fmt.Errorf("error"), 2', lines.get_line(50))
  end)

  it("prefers swapping an argument over its enclosing return call", function()
    vim.fn.cursor(58, 30) -- return fmt.Errorf("%s %s", "|first", "second"), 2

    tw.swap_right()

    assert.same('\treturn fmt.Errorf("%s %s", "second", "first"), 2', lines.get_line(58))
  end)

  it("swaps the enclosing call when the innermost argument has no right sibling", function()
    vim.fn.cursor(58, 39) -- return fmt.Errorf("%s %s", "first", "|second"), 2

    tw.swap_right()

    assert.same('\treturn 2, fmt.Errorf("%s %s", "first", "second")', lines.get_line(58))
  end)

  it("swaps statements right across a trailing comment without swapping the comment", function()
    vim.fn.cursor(64, 2) -- |return errors.New("error"), 2, errors.New("dsfsdf") // ...

    tw.swap_right()

    assert.same('\tc := 2' .. trailing_comment, lines.get_line(64))
    assert.same('\treturn errors.New("error"), 2, errors.New("dsfsdf")', lines.get_line(65))
  end)

  it("swaps statements left across a trailing comment without swapping the comment", function()
    vim.fn.cursor(65, 2) -- |c := 2

    tw.swap_left()

    assert.same('\tc := 2' .. trailing_comment, lines.get_line(64))
    assert.same('\treturn errors.New("error"), 2, errors.New("dsfsdf")', lines.get_line(65))
  end)

  it("does not swap a trailing comment as a starting node", function()
    vim.fn.cursor(64, 57) -- return ... // |swap any node ...

    tw.swap_right()

    assert.same('\treturn errors.New("error"), 2, errors.New("dsfsdf")' .. trailing_comment, lines.get_line(64))
    assert.same('\tc := 2', lines.get_line(65))
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

    it("confines swap_down", function()
      h.assert_swap_confined_by_parent(17, 1, 'down')
    end)

    it("confines swap_up", function()
      h.assert_swap_confined_by_parent(16, 1, 'up')
    end)

    it("confines swap_right", function()
      h.assert_swap_confined_by_parent(17, 1, 'right')
    end)

    it("confines swap_left", function()
      h.assert_swap_confined_by_parent(16, 1, 'left')
    end)
  end)
end)
