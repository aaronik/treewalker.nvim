local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local tw = require 'treewalker'
local lines = require 'treewalker.lines'
local h = require 'tests.treewalker.helpers'

describe("In a java file:", function()
  before_each(function()
    load_fixture("/java.java")
  end)

  h.ensure_has_parser("java")

  it("moves down between methods", function()
    vim.fn.cursor(34, 1) -- public String getName()
    tw.move_down()
    h.assert_cursor_at(39, 3) -- public void setName
  end)

  it("moves up between methods", function()
    vim.fn.cursor(39, 1) -- public void setName
    tw.move_up()
    h.assert_cursor_at(34, 3) -- public String getName
  end)

  it("moves into method body", function()
    vim.fn.cursor(34, 1) -- public String getName()
    tw.move_in()
    h.assert_cursor_at(35, 5) -- return name;
  end)

  it("moves out from method body to method", function()
    vim.fn.cursor(35, 1) -- return name;
    tw.move_out()
    h.assert_cursor_at(34, 3) -- public String getName()
  end)

  it("moves down between field declarations", function()
    vim.fn.cursor(15, 1) -- private String name;
    tw.move_down()
    h.assert_cursor_at(16, 3) -- private int count;
  end)

  it("moves into constructor body", function()
    vim.fn.cursor(20, 1) -- public JavaDemo()
    tw.move_in()
    h.assert_cursor_at(21, 5) -- this.name = "default";
  end)

  it("moves down between constructor statements", function()
    vim.fn.cursor(20, 1) -- this.name = "default";
    tw.move_down()
    h.assert_cursor_at(21, 5) -- this.count = 0;
  end)

  it("moves into if statement body", function()
    vim.fn.cursor(40, 1) -- if (name == null)
    tw.move_in()
    h.assert_cursor_at(41, 7) -- throw new IllegalArgumentException
  end)

  it("moves through for loop elements", function()
    vim.fn.cursor(58, 1) -- for (String name : names)
    tw.move_in()
    h.assert_cursor_at(59, 9) -- if (name != null...
  end)

  it("moves into try block", function()
    vim.fn.cursor(68, 1) -- try {
    tw.move_in()
    h.assert_cursor_at(69, 7) -- int value = Integer.parseInt(data);
  end)

  it("moves down within try block", function()
    vim.fn.cursor(68, 1) -- int value = ...
    tw.move_down()
    h.assert_cursor_at(69, 7) -- this.count = value;
  end)

  it("moves down within catch block", function()
    vim.fn.cursor(71, 1) -- System.err.println
    tw.move_down()
    h.assert_cursor_at(72, 7) -- this.count = 0;
  end)

  it("moves into switch statement", function()
    vim.fn.cursor(87, 1) -- switch (code)
    tw.move_in()
    h.assert_cursor_at(88, 7) -- case 200:
  end)

  it("moves down between switch cases", function()
    vim.fn.cursor(88, 1) -- case 200:
    tw.move_down()
    h.assert_cursor_at(90, 7) -- case 404:
  end)

  it("moves into while loop body", function()
    vim.fn.cursor(103, 1) -- while (i <= n)
    tw.move_in()
    h.assert_cursor_at(104, 7) -- sum += i;
  end)

  it("moves down between inner class methods", function()
    vim.fn.cursor(116, 1) -- public void put
    tw.move_in()
    h.assert_cursor_at(117, 7) -- data.put(key, value);
  end)

  it("moves down between enum values", function()
    vim.fn.cursor(133, 1) -- ACTIVE
    tw.move_down()
    h.assert_cursor_at(134, 5) -- INACTIVE
  end)

  it("moves down between interface methods", function()
    vim.fn.cursor(142, 1) -- void onComplete
    tw.move_down()
    h.assert_cursor_at(143, 5) -- void onError
  end)

  it("moves through lambda expression", function()
    vim.fn.cursor(80, 1) -- return numbers.stream()
    tw.move_in()
    h.assert_cursor_at(81, 7) -- .map(n -> n * 2)
  end)

  -- Skipping temporarily - CI is Ubuntu, and ubuntu treesitter is treating java (and other) comments
  -- much differently than macos.
  -- it("swaps methods down", function()
  --   vim.fn.cursor(34, 1) -- public String getName()
  --   local top_before = lines.get_lines(30, 36)
  --   local bottom_before = lines.get_lines(38, 44)
  --
  --   tw.swap_down()
  --
  --   h.assert_cursor_at(42, 3)
  --   assert.same(bottom_before, lines.get_lines(30, 36))
  --   assert.same(top_before, lines.get_lines(38, 44))
  -- end)

  -- it("swaps methods up", function()
  --   vim.fn.cursor(39, 1) -- public void setName
  --   local top_before = lines.get_lines(30, 36)
  --   local bottom_before = lines.get_lines(38, 44)
  --
  --   tw.swap_up()
  --
  --   h.assert_cursor_at(31, 3)
  --   assert.same(bottom_before, lines.get_lines(30, 36))
  --   assert.same(top_before, lines.get_lines(38, 44))
  -- end)

  it("swaps annotated methods down", function()
    vim.fn.cursor(154, 3) -- public String toString()
    local top_before = lines.get_lines(153, 157)
    local bottom_before = lines.get_lines(159, 165)

    tw.swap_down()

    h.assert_cursor_at(162, 3)
    assert.same(bottom_before, lines.get_lines(153, 159))
    assert.same(top_before, lines.get_lines(161, 165))
  end)

  it("moves down from javadoc comment to method", function()
    vim.fn.cursor(31, 1) -- * Gets the name value
    tw.move_down()
    h.assert_cursor_at(34, 3) -- public String getName()
  end)

  -- it("moves out from inside javadoc to class", function()
  --   vim.fn.cursor(31, 1) -- * Gets the name value
  --   tw.move_out()
  --   h.assert_cursor_at(13, 1) -- public class JavaDemo
  -- end)

  it("handles main method with multiple statements", function()
    vim.fn.cursor(187, 1) -- public static void main
    tw.move_in()
    h.assert_cursor_at(188, 5) -- JavaDemo demo = new JavaDemo
  end)

  it("moves through statements in main", function()
    vim.fn.cursor(188, 1) -- JavaDemo demo = new JavaDemo
    tw.move_down()
    h.assert_cursor_at(189, 5) -- System.out.println(demo.getName())
  end)
end)
