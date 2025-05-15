local load_fixture = require("tests.load_fixture")
local assert = require("luassert")
local tw = require("treewalker")
local lines = require("treewalker.lines")
local h = require("tests.treewalker.helpers")

describe("In a rust file:", function()
  before_each(function()
    load_fixture("/rust.rs")
  end)

  h.ensure_has_parser("rust")

  it("Swaps enum values right", function()
    vim.fn.cursor(49, 14)
    assert.same("enum Color { Red, Green, Blue }", lines.get_line(49))
    tw.swap_right()
    assert.same("enum Color { Green, Red, Blue }", lines.get_line(49))
    h.assert_cursor_at(49, 21, "Red")
  end)

  it("Swaps enum values left", function()
    vim.fn.cursor(49, 19)
    assert.same("enum Color { Red, Green, Blue }", lines.get_line(49))
    tw.swap_left()
    assert.same("enum Color { Green, Red, Blue }", lines.get_line(49))
    h.assert_cursor_at(49, 14, "Red")
  end)

  -- The below issue is also happening in TSTextObjectSwapNext/Prev @parameter.inner
  -- In rust, node:parent() is taking us to a node that is way higher up than what
  -- appears to be the parent (via via.treesitter.inspect_tree())
  pending("Swaps right from a string to a fn call", function()
    vim.fn.cursor(46, 18) -- inside shape
    assert.same('    println!("shape_area", calculate_area(shape));', lines.get_line(46))
    tw.swap_right()
    assert.same('    println!(calculate_area(shape), "shape_area");', lines.get_line(46))
  end)

  pending("Swaps laterally from a string to a fn call", function()
    vim.fn.cursor(46, 32) -- inside calculate
    assert.same('    println!("shape_area", calculate_area(shape));', lines.get_line(46))
    tw.swap_left()
    assert.same('    println!(calculate_area(shape), "shape_area");', lines.get_line(46))
  end)
end)
