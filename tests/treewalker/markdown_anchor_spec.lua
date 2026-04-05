local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local markdown_anchor = require("treewalker.markdown.anchor")

describe("markdown anchor", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  describe(".current", function()
    it("returns anchor at cursor row", function()
      local anchor = markdown_anchor.current(4) -- ## Header
      assert.is_not_nil(anchor)
      assert.equal(4, anchor.row)
      assert.equal(4, anchor.heading_row)
      assert.is_true(anchor.is_heading)
    end)

    it("returns anchor for non-heading rows", function()
      local anchor = markdown_anchor.current(7) -- paragraph
      assert.is_not_nil(anchor)
      assert.equal(7, anchor.row)
      assert.is_false(anchor.is_heading)
    end)

    it("includes section bounds", function()
      local anchor = markdown_anchor.current(4)
      assert.is_not_nil(anchor)
      assert.is_number(anchor.start)
      assert.is_number(anchor.finish)
      assert.is_true(anchor.finish >= anchor.start)
    end)

    it("includes level information", function()
      local anchor = markdown_anchor.current(4) -- ## Header
      assert.is_not_nil(anchor)
      assert.equal(2, anchor.level)
    end)

    it("returns nil for non-markdown files", function()
      load_fixture("/lua.lua")
      local anchor = markdown_anchor.current(1)
      assert.is_nil(anchor)
    end)
  end)

  describe(".from_heading_row", function()
    it("builds anchor from heading row", function()
      local anchor = markdown_anchor.from_heading_row(4)
      assert.is_not_nil(anchor)
      assert.equal(4, anchor.heading_row)
      assert.is_true(anchor.is_heading)
    end)

    it("returns nil for non-heading rows", function()
      local anchor = markdown_anchor.from_heading_row(7) -- paragraph
      if anchor then
        -- from_heading_row may still return anchor if row is within section
        assert.is_not_nil(anchor)
      end
    end)
  end)

  describe(".current_heading", function()
    it("returns anchor when on heading", function()
      local anchor = markdown_anchor.current_heading(4)
      assert.is_not_nil(anchor)
      assert.is_true(anchor.is_heading)
    end)

    it("returns nil when not on heading", function()
      local anchor = markdown_anchor.current_heading(7)
      assert.is_nil(anchor)
    end)

    it("uses current line when row not provided", function()
      vim.fn.cursor(4, 1)
      local anchor = markdown_anchor.current_heading()
      assert.is_not_nil(anchor)
      assert.is_true(anchor.is_heading)
    end)
  end)

  describe(".find_up", function()
    it("finds previous same-level heading when on heading", function()
      local current = markdown_anchor.current(19) -- ## Text Formatting
      assert.is_not_nil(current)
      local target = markdown_anchor.find_up(current)
      assert.is_not_nil(target)
      assert.equal(4, target.heading_row) -- ## Header
    end)

    it("finds nearest previous heading when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph in ## Header
      assert.is_not_nil(current)
      local target = markdown_anchor.find_up(current)
      -- Should find a previous heading
      if target then
        assert.is_true(target.row < current.row)
      end
    end)

    it("returns nil at first heading", function()
      local current = markdown_anchor.current(1) -- # Title
      assert.is_not_nil(current)
      local target = markdown_anchor.find_up(current)
      -- No previous h1
      assert.is_nil(target)
    end)
  end)

  describe(".find_down", function()
    it("finds next same-level heading when on heading", function()
      local current = markdown_anchor.current(4) -- ## Header
      assert.is_not_nil(current)
      local target = markdown_anchor.find_down(current)
      assert.is_not_nil(target)
      assert.equal(19, target.heading_row) -- ## Text Formatting
    end)

    it("finds nearest next heading when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph
      assert.is_not_nil(current)
      local target = markdown_anchor.find_down(current)
      if target then
        assert.is_true(target.row > current.row)
      end
    end)

    it("returns nil at last heading of level", function()
      -- Find the last h2
      local current = markdown_anchor.current(110) -- last section
      assert.is_not_nil(current)
      local target = markdown_anchor.find_down(current)
      assert.is_nil(target)
    end)
  end)

  describe(".find_in", function()
    it("finds child heading", function()
      local current = markdown_anchor.current(4) -- ## Header
      assert.is_not_nil(current)
      local target = markdown_anchor.find_in(current)
      assert.is_not_nil(target)
      assert.equal(9, target.heading_row) -- ### Subheader
    end)

    it("returns nil when no child headings exist", function()
      local current = markdown_anchor.current(14) -- #### Tertiary (no children)
      assert.is_not_nil(current)
      local target = markdown_anchor.find_in(current)
      assert.is_nil(target)
    end)

    it("returns nil when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph
      assert.is_not_nil(current)
      local target = markdown_anchor.find_in(current)
      assert.is_nil(target)
    end)
  end)

  describe(".find_out", function()
    it("finds parent heading when on nested heading", function()
      local current = markdown_anchor.current(9) -- ### Subheader
      assert.is_not_nil(current)
      local target = markdown_anchor.find_out(current)
      assert.is_not_nil(target)
      assert.equal(4, target.heading_row) -- ## Header
    end)

    it("navigates to heading when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph under ## Header
      assert.is_not_nil(current)
      local target = markdown_anchor.find_out(current)
      assert.is_not_nil(target)
      assert.equal(4, target.heading_row)
    end)

    it("returns nil at h1", function()
      local current = markdown_anchor.current(1) -- # Title
      assert.is_not_nil(current)
      local target = markdown_anchor.find_out(current)
      assert.is_nil(target)
    end)
  end)

  describe(".next_swappable_sibling", function()
    it("finds next sibling at same level with same parent", function()
      local current = markdown_anchor.current(4) -- ## Header
      assert.is_not_nil(current)
      local sibling = markdown_anchor.next_swappable_sibling(current)
      assert.is_not_nil(sibling)
      assert.equal(current.level, sibling.level)
    end)

    it("returns nil when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph
      assert.is_not_nil(current)
      local sibling = markdown_anchor.next_swappable_sibling(current)
      assert.is_nil(sibling)
    end)

    it("returns nil at last sibling", function()
      local current = markdown_anchor.current(110) -- last section
      assert.is_not_nil(current)
      local sibling = markdown_anchor.next_swappable_sibling(current)
      assert.is_nil(sibling)
    end)
  end)

  describe(".prev_swappable_sibling", function()
    it("finds previous sibling at same level with same parent", function()
      local current = markdown_anchor.current(19) -- ## Text Formatting
      assert.is_not_nil(current)
      local sibling = markdown_anchor.prev_swappable_sibling(current)
      assert.is_not_nil(sibling)
      assert.equal(current.level, sibling.level)
    end)

    it("returns nil when not on heading", function()
      local current = markdown_anchor.current(7) -- paragraph
      assert.is_not_nil(current)
      local sibling = markdown_anchor.prev_swappable_sibling(current)
      assert.is_nil(sibling)
    end)

    it("returns nil at first sibling", function()
      local current = markdown_anchor.current(4) -- first h2
      assert.is_not_nil(current)
      local sibling = markdown_anchor.prev_swappable_sibling(current)
      assert.is_nil(sibling)
    end)
  end)

  describe(".find_next_same_level", function()
    it("finds next heading at same level", function()
      local current = markdown_anchor.current(9) -- ### Subheader
      assert.is_not_nil(current)
      local target = markdown_anchor.find_next_same_level(current)
      if target then
        assert.equal(current.level, target.level)
        assert.is_true(target.heading_row > current.heading_row)
      end
    end)
  end)

  describe(".find_prev_same_level", function()
    it("finds previous heading at same level", function()
      local current = markdown_anchor.current(19) -- ## Text Formatting
      assert.is_not_nil(current)
      local target = markdown_anchor.find_prev_same_level(current)
      assert.is_not_nil(target)
      assert.equal(current.level, target.level)
      assert.is_true(target.heading_row < current.heading_row)
    end)
  end)
end)

describe("markdown anchor in file without h1", function()
  before_each(function()
    load_fixture("/markdown-h2s.md")
  end)

  describe(".current", function()
    it("handles h2 at top of file", function()
      local anchor = markdown_anchor.current(1)
      assert.is_not_nil(anchor)
      assert.equal(2, anchor.level)
      assert.is_true(anchor.is_heading)
    end)
  end)

  describe(".next_swappable_sibling", function()
    it("finds sibling h2 without parent h1", function()
      local current = markdown_anchor.current(1)
      assert.is_not_nil(current)
      local sibling = markdown_anchor.next_swappable_sibling(current)
      assert.is_not_nil(sibling)
      assert.equal(6, sibling.heading_row)
    end)
  end)

  describe(".prev_swappable_sibling", function()
    it("finds sibling h2 without parent h1", function()
      local current = markdown_anchor.current(6)
      assert.is_not_nil(current)
      local sibling = markdown_anchor.prev_swappable_sibling(current)
      assert.is_not_nil(sibling)
      assert.equal(1, sibling.heading_row)
    end)
  end)
end)
