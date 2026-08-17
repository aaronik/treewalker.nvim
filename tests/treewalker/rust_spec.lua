local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("In a rust file:", function()
  before_each(function()
    load_fixture("/rust.rs")
  end)

  h.ensure_has_parser("rust")

  it("Does not hang moving up from a leading blank line", function()
    vim.fn.cursor(1, 1)
    tw.move_up()
    h.assert_cursor_at(1, 1)
  end)

  it("Swaps enum values right", function()
    vim.fn.cursor(50, 14)
    assert.same('enum Color { Red, Green, Blue }', lines.get_line(50))
    tw.swap_right()
    assert.same('enum Color { Green, Red, Blue }', lines.get_line(50))
    h.assert_cursor_at(50, 21, "Red")
  end)

  it("Swaps enum values left", function()
    vim.fn.cursor(50, 19)
    assert.same('enum Color { Red, Green, Blue }', lines.get_line(50))
    tw.swap_left()
    assert.same('enum Color { Green, Red, Blue }', lines.get_line(50))
    h.assert_cursor_at(50, 14, "Red")
  end)

  -- Stopped working for Christmas 2025 (ts parser issue)
  pending("Swaps right from a string to a fn call", function()
    vim.fn.cursor(47, 18) -- inside shape
    assert.same('    println!("shape_area", calculate_area(shape));', lines.get_line(47))
    tw.swap_right()
    assert.same('    println!(calculate_area(shape), "shape_area");', lines.get_line(47))
  end)

  pending("Swaps laterally from a string to a fn call", function()
    vim.fn.cursor(47, 32) -- inside calculate
    assert.same('    println!("shape_area", calculate_area(shape));', lines.get_line(47))
    tw.swap_left()
    assert.same('    println!(calculate_area(shape), "shape_area");', lines.get_line(47))
  end)
  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(20, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(16, 1, 'up')
    end)

    it("confines swap_down", function()
      h.assert_swap_confined_by_parent(20, 1, 'down')
    end)

    it("confines swap_up", function()
      h.assert_swap_confined_by_parent(16, 1, 'up')
    end)

    it("confines swap_right", function()
      h.assert_swap_confined_by_parent(20, 1, 'right')
    end)

    it("confines swap_left", function()
      h.assert_swap_confined_by_parent(16, 1, 'left')
    end)
  end)
end)
