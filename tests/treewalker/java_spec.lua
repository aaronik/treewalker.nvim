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
    vim.fn.cursor(34, 3) -- public String getName()
    tw.move_down()
    h.assert_cursor_at(39, 3) -- public void setName
  end)

  it("moves up between methods", function()
    vim.fn.cursor(39, 3) -- public void setName
    tw.move_up()
    h.assert_cursor_at(34, 3) -- public String getName
  end)

  it("moves into method body", function()
    vim.fn.cursor(34, 3) -- public String getName()
    tw.move_in()
    h.assert_cursor_at(35, 5) -- return name;
  end)

  it("moves out from method body to method", function()
    vim.fn.cursor(35, 5) -- return name;
    tw.move_out()
    h.assert_cursor_at(34, 3) -- public String getName()
  end)

  it("moves into if statement body", function()
    vim.fn.cursor(40, 5) -- if (name == null)
    tw.move_in()
    h.assert_cursor_at(41, 7) -- throw new IllegalArgumentException
  end)

  it("moves into try block", function()
    vim.fn.cursor(67, 5) -- try {
    tw.move_in()
    h.assert_cursor_at(68, 7) -- int value = Integer.parseInt(data);
  end)

  it("moves into switch statement", function()
    vim.fn.cursor(86, 3) -- switch (code)
    tw.move_in()
    h.assert_cursor_at(87, 5) -- case 200:
    tw.move_in()
    h.assert_cursor_at(88, 7)
    tw.move_in()
    h.assert_cursor_at(89, 9)
  end)

  it("moves down between switch cases", function()
    vim.fn.cursor(88, 7) -- case 200:
    tw.move_down()
    h.assert_cursor_at(90, 7) -- case 404:
    tw.move_down()
    h.assert_cursor_at(92, 7)
    tw.move_down()
    h.assert_cursor_at(94, 7)
  end)

  it("moves into while loop body", function()
    vim.fn.cursor(103, 1) -- while (i <= n)
    tw.move_in()
    h.assert_cursor_at(104, 7) -- sum += i;
  end)

  it("moves down between enum values", function()
    vim.fn.cursor(133, 5) -- ACTIVE
    tw.move_down()
    h.assert_cursor_at(134, 5) -- INACTIVE
  end)

  it("moves down between interface methods", function()
    vim.fn.cursor(142, 5) -- void onComplete
    tw.move_down()
    h.assert_cursor_at(143, 5) -- void onError
  end)

  it("moves through lambda expression", function()
    vim.fn.cursor(80, 7) -- return numbers.stream()
    tw.move_in()
    h.assert_cursor_at(81, 7) -- .map(n -> n * 2)
  end)

  it("swaps methods down", function()
    vim.fn.cursor(34, 1) -- public String getName()
    local top_before = lines.get_lines(30, 36)
    local bottom_before = lines.get_lines(38, 44)

    tw.swap_down()

    h.assert_cursor_at(42, 3)
    assert.same(bottom_before, lines.get_lines(30, 36))
    assert.same(top_before, lines.get_lines(38, 44))
  end)

  it("swaps methods up", function()
    vim.fn.cursor(39, 1) -- public void setName
    local top_before = lines.get_lines(30, 36)
    local bottom_before = lines.get_lines(38, 44)

    tw.swap_up()

    h.assert_cursor_at(31, 3)
    assert.same(bottom_before, lines.get_lines(30, 36))
    assert.same(top_before, lines.get_lines(38, 44))
  end)

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
    vim.fn.cursor(31, 9) -- * Gets the name value
    tw.move_down()
    h.assert_cursor_at(34, 3) -- public String getName()
  end)

  it("moves out from inside javadoc to class", function()
    vim.fn.cursor(31, 1) -- * Gets the name value
    tw.move_out()
    h.assert_cursor_at(13, 1) -- public class JavaDemo
  end)
end)
