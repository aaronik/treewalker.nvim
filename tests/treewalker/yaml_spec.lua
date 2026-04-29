local load_fixture = require "tests.load_fixture"
local assert = require "luassert"
local lines = require 'treewalker.lines'
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

describe("Movement in a YAML file:", function()
  before_each(function()
    load_fixture("/yaml.yml")
  end)

  h.ensure_has_parser("yaml")

  it("moves in", function()
    vim.fn.cursor(1, 1)
    tw.move_in()
    h.assert_cursor_at(2, 3)
    tw.move_in()
    h.assert_cursor_at(7, 5)
  end)

  it("moves down on keys", function()
    vim.fn.cursor(2, 3)
    tw.move_down()
    h.assert_cursor_at(3, 3)
    tw.move_down()
    h.assert_cursor_at(4, 3)
    tw.move_down()
    h.assert_cursor_at(5, 3)
    tw.move_down()
    h.assert_cursor_at(6, 3)
    tw.move_down()
    h.assert_cursor_at(10, 3)
    tw.move_down()
    h.assert_cursor_at(19, 3)
    tw.move_down()
    h.assert_cursor_at(23, 3)
    tw.move_down()
    h.assert_cursor_at(26, 3)
    tw.move_down()
    h.assert_cursor_at(27, 3)
    tw.move_down()
    h.assert_cursor_at(28, 3)
    tw.move_down()
    h.assert_cursor_at(29, 3)
    tw.move_down()
    h.assert_cursor_at(35, 3)
    tw.move_down()
    h.assert_cursor_at(43, 3)
  end)

  it("moves up on keys", function()
    vim.fn.cursor(35, 3)
    tw.move_up()
    h.assert_cursor_at(29, 3)
    tw.move_up()
    h.assert_cursor_at(28, 3)
    tw.move_up()
    h.assert_cursor_at(27, 3)
    tw.move_up()
    h.assert_cursor_at(26, 3)
    tw.move_up()
    h.assert_cursor_at(23, 3)
    tw.move_up()
    h.assert_cursor_at(19, 3)
    tw.move_up()
    h.assert_cursor_at(10, 3)
    tw.move_up()
    h.assert_cursor_at(6, 3)
    tw.move_up()
    h.assert_cursor_at(5, 3)
    tw.move_up()
    h.assert_cursor_at(4, 3)
    tw.move_up()
    h.assert_cursor_at(3, 3)
    tw.move_up()
    h.assert_cursor_at(2, 3)
  end)

  it("moves out within just keys", function()
    vim.fn.cursor(30, 5) -- red: null
    tw.move_out()
    h.assert_cursor_at(29, 3)
    tw.move_out()
    h.assert_cursor_at(1, 1)
  end)

  it("moves out within arrays", function()
    vim.fn.cursor(41, 9) -- theme: dark
    tw.move_out()
    h.assert_cursor_at(40, 7)
    tw.move_out()
    h.assert_cursor_at(38, 5)
    tw.move_out()
    h.assert_cursor_at(35, 3)
    tw.move_out()
    h.assert_cursor_at(34, 1)
  end)

  it("moves down in array", function()
    vim.fn.cursor(7, 5) -- - authentication
    tw.move_down()
    h.assert_cursor_at(8, 5)
    tw.move_down()
    h.assert_cursor_at(9, 5)
  end)

  it("moves up in array", function()
    vim.fn.cursor(9, 5) -- - notifications
    tw.move_up()
    h.assert_cursor_at(8, 5)
    tw.move_up()
    h.assert_cursor_at(7, 5)
  end)

  it("navigates mixedList part", function()
    vim.fn.cursor(72, 1) -- mixedList:
    tw.move_in()
    h.assert_cursor_at(73, 3)
    tw.move_down()
    h.assert_cursor_at(74, 3)
    tw.move_in()
    h.assert_cursor_at(78, 5)
    tw.move_out()
    h.assert_cursor_at(77, 3)
    tw.move_out()
    h.assert_cursor_at(72, 1)
  end)

  it("navigates complexKeys part", function()
    vim.fn.cursor(49, 1) -- complexKeys:
    tw.move_in()
    h.assert_cursor_at(50, 3)
    tw.move_down()
    h.assert_cursor_at(52, 3)
    tw.move_in()
    h.assert_cursor_at(55, 5)
    tw.move_out()
    h.assert_cursor_at(54, 3)
    tw.move_out()
    h.assert_cursor_at(49, 1)
  end)

  it("moves down across top-level keys", function()
    vim.fn.cursor(1, 1) -- appConfig:
    tw.move_down()
    h.assert_cursor_at(34, 1)
    tw.move_down()
    h.assert_cursor_at(49, 1)
    tw.move_down()
    h.assert_cursor_at(60, 1)
  end)

  it("moves up across top-level keys", function()
    vim.fn.cursor(49, 1) -- complexKeys:
    tw.move_up()
    h.assert_cursor_at(34, 1)
    tw.move_up()
    h.assert_cursor_at(1, 1)
  end)

  it("swaps a top-level key up", function()
    vim.fn.cursor(34, 1) -- users:
    local app_config_before = lines.get_lines(1, 32)
    local users_before = lines.get_lines(34, 47)

    tw.swap_up()

    h.assert_cursor_at(1, 1)
    assert.same(users_before, lines.get_lines(1, 14))
    assert.same(app_config_before, lines.get_lines(16, 47))
  end)

  it("swaps a top-level key down", function()
    vim.fn.cursor(34, 1) -- users:
    local users_before = lines.get_lines(34, 47)
    local complex_keys_before = lines.get_lines(49, 58)

    tw.swap_down()

    h.assert_cursor_at(45, 1)
    assert.same(complex_keys_before, lines.get_lines(34, 43))
    assert.same(users_before, lines.get_lines(45, 58))
  end)

  it("swaps a yaml list item when targeting the dash", function()
    vim.fn.cursor(35, 3) -- - id: 1001
    local first_user_before = lines.get_lines(35, 42)
    local second_user_before = lines.get_lines(43, 47)

    tw.swap_down()

    h.assert_cursor_at(40, 3)
    assert.same(second_user_before, lines.get_lines(35, 39))
    assert.same(first_user_before, lines.get_lines(40, 47))
  end)

  it("swaps a key within a yaml list item without moving the whole item", function()
    vim.fn.cursor(36, 5) -- name: "Alice"
    local first_user_before = lines.get_lines(35, 42)

    tw.swap_down()

    h.assert_cursor_at(37, 5)
    assert.same({
      first_user_before[1],
      first_user_before[3],
      first_user_before[2],
      first_user_before[4],
      first_user_before[5],
      first_user_before[6],
      first_user_before[7],
      first_user_before[8],
    }, lines.get_lines(35, 42))
  end)

  it("swaps up nested yaml keys with their child block", function()
    vim.fn.cursor(68, 3) -- nestedEmpty:
    local empty_map_before = lines.get_lines(67, 67)
    local nested_empty_before = lines.get_lines(68, 70)

    tw.swap_up()

    h.assert_cursor_at(67, 3)
    assert.same(nested_empty_before, lines.get_lines(67, 69))
    assert.same(empty_map_before, lines.get_lines(70, 70))
  end)

  it("swaps down across an augmented top-level key", function()
    vim.fn.cursor(81, 1) -- anchorsAndAliases:
    local anchors_and_aliases_before = lines.get_lines(81, 90)
    local explicit_tag_before = lines.get_lines(92, 93)

    tw.swap_down()

    h.assert_cursor_at(84, 1)
    assert.same(explicit_tag_before, lines.get_lines(81, 82))
    assert.same(anchors_and_aliases_before, lines.get_lines(84, 93))
  end)

  describe("scope_confined", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("confines move_down", function()
      h.assert_confined_by_parent(44, 1, 'down')
    end)

    it("confines move_up", function()
      h.assert_confined_by_parent(43, 1, 'up')
    end)

    it("confines swap_down", function()
      h.assert_swap_confined_by_parent(44, 1, 'down')
    end)

    it("confines swap_up", function()
      h.assert_swap_confined_by_parent(43, 1, 'up')
    end)

    it("confines swap_right", function()
      h.assert_swap_confined_by_parent(44, 1, 'right')
    end)

    it("confines swap_left", function()
      h.assert_swap_confined_by_parent(43, 1, 'left')
    end)

    it("stays within the current yaml parent on move_down", function()
      vim.fn.cursor(47, 5) -- metadata: *userMeta

      tw.move_down()

      h.assert_cursor_at(47, 5)
    end)

    it("stays within the current yaml parent on swap_down", function()
      vim.fn.cursor(47, 5) -- metadata: *userMeta
      local before = lines.get_lines(34, 72)

      tw.swap_down()

      h.assert_cursor_at(47, 5)
      assert.same(before, lines.get_lines(34, 72))
    end)
  end)
end)
