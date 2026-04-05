local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local swap_section = require("treewalker.markdown.swap.section")
local markdown_anchor = require("treewalker.markdown.anchor")
local lines = require("treewalker.lines")

describe("markdown swap section", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  describe(".swap_markdown_sections", function()
    it("swaps two sections at the same level", function()
      local current = markdown_anchor.current(4) -- ## Header
      local target = markdown_anchor.current(19) -- ## Text Formatting
      assert.is_not_nil(current)
      assert.is_not_nil(target)

      local original_4 = lines.get_line(4)
      local original_19 = lines.get_line(19)

      local ok, new_pos = swap_section.swap_markdown_sections(current, target, "down")

      assert.is_true(ok)
      assert.is_not_nil(new_pos)

      -- Content should have been swapped
      local after_4 = lines.get_line(4)
      assert.is_true(after_4 ~= original_4 or after_4:find("Text Formatting"))
    end)

    it("returns false for sections at different levels", function()
      local current = markdown_anchor.current(4) -- ## Header (level 2)
      local target = markdown_anchor.current(9) -- ### Subheader (level 3)
      assert.is_not_nil(current)
      assert.is_not_nil(target)

      local original = lines.get_lines(1, 20)

      local ok, _ = swap_section.swap_markdown_sections(current, target, "down")

      assert.is_false(ok)
      -- Content should not have changed
      assert.same(original, lines.get_lines(1, 20))
    end)

    it("returns false for sections with different parents", function()
      -- h3 under one h2 vs h3 under different h2
      local current = markdown_anchor.current(9) -- ### Subheader under ## Header
      local target = markdown_anchor.current(41) -- ### Another Header under ## Headers Again

      if current and target then
        -- These have different parents
        if current.parent_row ~= target.parent_row then
          local ok, _ = swap_section.swap_markdown_sections(current, target, "down")
          assert.is_false(ok)
        end
      end
    end)

    it("returns correct cursor position for swap down", function()
      local current = markdown_anchor.current(4)
      local target = markdown_anchor.current(19)
      assert.is_not_nil(current)
      assert.is_not_nil(target)

      local _, new_pos = swap_section.swap_markdown_sections(current, target, "down")

      assert.is_number(new_pos)
      assert.is_true(new_pos > 4) -- cursor should move down
    end)

    it("returns correct cursor position for swap up", function()
      local current = markdown_anchor.current(19)
      local target = markdown_anchor.current(4)
      assert.is_not_nil(current)
      assert.is_not_nil(target)

      local _, new_pos = swap_section.swap_markdown_sections(current, target, "up")

      assert.is_number(new_pos)
    end)
  end)

  describe(".swap_down_markdown", function()
    it("finds target and swaps sections", function()
      vim.fn.cursor(4, 1) -- ## Header
      local original = lines.get_lines(1, 25)

      swap_section.swap_down_markdown()

      local after = lines.get_lines(1, 25)
      assert.is_true(vim.inspect(original) ~= vim.inspect(after))
    end)

    it("does nothing when not on heading", function()
      vim.fn.cursor(7, 1) -- paragraph
      local original = lines.get_lines(1, 20)

      swap_section.swap_down_markdown()

      assert.same(original, lines.get_lines(1, 20))
    end)

    it("does nothing when no next sibling", function()
      -- Go to last h2
      vim.fn.cursor(110, 1)
      local original = lines.get_lines(100, 135)

      swap_section.swap_down_markdown()

      assert.same(original, lines.get_lines(100, 135))
    end)

    it("moves cursor to new position after swap", function()
      vim.fn.cursor(4, 1)
      swap_section.swap_down_markdown()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[2] > 4)
    end)
  end)

  describe(".swap_up_markdown", function()
    it("finds target and swaps sections", function()
      vim.fn.cursor(19, 1) -- ## Text Formatting
      local original = lines.get_lines(1, 25)

      swap_section.swap_up_markdown()

      local after = lines.get_lines(1, 25)
      assert.is_true(vim.inspect(original) ~= vim.inspect(after))
    end)

    it("does nothing when not on heading", function()
      vim.fn.cursor(7, 1) -- paragraph
      local original = lines.get_lines(1, 20)

      swap_section.swap_up_markdown()

      assert.same(original, lines.get_lines(1, 20))
    end)

    it("does nothing when no previous sibling", function()
      vim.fn.cursor(4, 1) -- first h2
      local original = lines.get_lines(1, 25)

      swap_section.swap_up_markdown()

      assert.same(original, lines.get_lines(1, 25))
    end)

    it("moves cursor to new position after swap", function()
      vim.fn.cursor(19, 1)
      swap_section.swap_up_markdown()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[2] < 19)
    end)
  end)
end)

describe("markdown swap section in file with h2s at top", function()
  before_each(function()
    load_fixture("/markdown-h2s.md")
  end)

  describe(".swap_down_markdown", function()
    it("swaps h2s without h1 parent", function()
      vim.fn.cursor(1, 1)
      local original_line_1 = lines.get_line(1)

      swap_section.swap_down_markdown()

      local after_line_1 = lines.get_line(1)
      assert.is_true(after_line_1 ~= original_line_1)
    end)
  end)

  describe(".swap_up_markdown", function()
    it("swaps h2s without h1 parent", function()
      vim.fn.cursor(6, 1)
      local original_line_6 = lines.get_line(6)

      swap_section.swap_up_markdown()

      local after_line_6 = lines.get_line(6)
      -- After swap, content should be different
      assert.is_true(after_line_6 ~= original_line_6)
    end)
  end)
end)
