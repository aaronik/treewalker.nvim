local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local heading = require("treewalker.markdown.heading")
local nodes = require("treewalker.nodes")

describe("markdown heading", function()
  before_each(function()
    load_fixture("/markdown.md")
  end)

  describe(".heading_info", function()
    it("returns heading type and level for ATX headings", function()
      local info = heading.heading_info(4) -- ## Header
      assert.equal("heading", info.type)
      assert.equal(2, info.level)
    end)

    it("returns heading type and level for h3 headings", function()
      local info = heading.heading_info(9) -- ### Subheader
      assert.equal("heading", info.type)
      assert.equal(3, info.level)
    end)

    it("returns heading type and level for h4 headings", function()
      local info = heading.heading_info(14) -- #### Tertiary Header
      assert.equal("heading", info.type)
      assert.equal(4, info.level)
    end)

    it("returns 'none' type for non-heading rows", function()
      local info = heading.heading_info(7) -- paragraph text
      assert.equal("none", info.type)
    end)

    it("returns 'none' type for empty rows", function()
      local info = heading.heading_info(2) -- empty line
      assert.equal("none", info.type)
    end)
  end)

  describe(".get_heading_level_from_node", function()
    it("extracts level from atx_heading node", function()
      local node = nodes.get_at_row(4) -- ## Header
      assert.is_not_nil(node)

      -- Find the atx_heading node
      local heading_node = node
      while heading_node and heading_node:type() ~= "atx_heading" do
        heading_node = heading_node:parent()
      end

      if heading_node then
        local level = heading.get_heading_level_from_node(heading_node)
        assert.equal(2, level)
      end
    end)

    it("returns nil for non-heading nodes", function()
      local node = nodes.get_at_row(7) -- paragraph
      assert.is_not_nil(node)
      local level = heading.get_heading_level_from_node(node)
      assert.is_nil(level)
    end)
  end)

  describe(".get_section_bounds", function()
    it("returns level, start, and end for a heading section", function()
      local level, start_row, end_row = heading.get_section_bounds(4) -- ## Header
      assert.equal(2, level)
      assert.equal(4, start_row)
      assert.is_not_nil(end_row)
      assert.is_true(end_row > start_row)
    end)

    it("returns correct bounds for nested sections", function()
      local level, start_row, end_row = heading.get_section_bounds(9) -- ### Subheader
      assert.equal(3, level)
      assert.equal(9, start_row)
      assert.is_not_nil(end_row)
    end)

    it("returns nil values for non-heading rows", function()
      local level, start_row, end_row = heading.get_section_bounds(7) -- paragraph
      assert.is_nil(level)
      assert.is_nil(start_row)
      assert.is_nil(end_row)
    end)

    it("returns nil for rows beyond file", function()
      local level, start_row, end_row = heading.get_section_bounds(9999)
      assert.is_nil(level)
      assert.is_nil(start_row)
      assert.is_nil(end_row)
    end)
  end)

  describe(".find_parent_header", function()
    it("finds parent for nested heading", function()
      local parent_row, parent_level = heading.find_parent_header(9, 3) -- ### Subheader
      assert.equal(4, parent_row) -- ## Header
      assert.equal(2, parent_level)
    end)

    it("finds parent for deeply nested heading", function()
      local parent_row, parent_level = heading.find_parent_header(14, 4) -- #### Tertiary Header
      assert.equal(9, parent_row) -- ### Subheader
      assert.equal(3, parent_level)
    end)

    it("returns nil for top-level headings", function()
      local parent_row, parent_level = heading.find_parent_header(1, 1) -- # Title
      assert.is_nil(parent_row)
      assert.is_nil(parent_level)
    end)

    it("returns nil for h2 without h1 parent", function()
      -- In markdown-h2s.md, h2s are at top level
      load_fixture("/markdown-h2s.md")
      local parent_row, parent_level = heading.find_parent_header(1, 2)
      assert.is_nil(parent_row)
      assert.is_nil(parent_level)
    end)
  end)

  describe(".get_parent_section_bounds", function()
    it("returns parent section bounds for nested heading", function()
      local level, start_row, end_row = heading.get_parent_section_bounds(9, 3)
      -- Parent is ## Header at row 4
      assert.equal(2, level)
      assert.equal(4, start_row)
      assert.is_not_nil(end_row)
    end)

    it("returns document bounds for top-level headings", function()
      local level, start_row, end_row = heading.get_parent_section_bounds(4, 2)
      -- No parent, should return document bounds
      assert.is_nil(level)
      assert.equal(1, start_row)
      assert.is_not_nil(end_row)
    end)
  end)

  describe(".get_section_heading_row_and_node", function()
    it("returns heading row and node from section", function()
      local root = nodes.get_root()
      assert.is_not_nil(root)

      -- Find a section node
      local function find_section(node)
        if node:type() == "section" then
          return node
        end
        for child in node:iter_children() do
          local found = find_section(child)
          if found then return found end
        end
        return nil
      end

      local section = find_section(root)
      if section then
        local row, node = heading.get_section_heading_row_and_node(section)
        assert.is_not_nil(row)
        assert.is_not_nil(node)
        assert.equal("atx_heading", node:type())
      end
    end)
  end)

  describe(".get_section_level", function()
    it("returns level from section node", function()
      local root = nodes.get_root()
      assert.is_not_nil(root)

      local function find_section(node)
        if node:type() == "section" then
          return node
        end
        for child in node:iter_children() do
          local found = find_section(child)
          if found then return found end
        end
        return nil
      end

      local section = find_section(root)
      if section then
        local level = heading.get_section_level(section)
        assert.is_not_nil(level)
        assert.is_true(level >= 1 and level <= 6)
      end
    end)
  end)

  describe(".find_child_of_type", function()
    it("finds child of specified type", function()
      local root = nodes.get_root()
      assert.is_not_nil(root)

      -- Find section node
      local section = heading.find_child_of_type(root, "section")
      if section then
        assert.equal("section", section:type())
      end
    end)

    it("returns nil when child type not found", function()
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)
      local child = heading.find_child_of_type(node, "nonexistent_type")
      assert.is_nil(child)
    end)
  end)

  describe(".find_section_matching", function()
    it("finds section matching predicate", function()
      local root = nodes.get_root()
      assert.is_not_nil(root)

      local found_node, found_row = heading.find_section_matching(root, function(_, section_row, _)
        return section_row == 4
      end)

      assert.is_not_nil(found_node)
      assert.equal(4, found_row)
    end)

    it("returns nil when no section matches", function()
      local root = nodes.get_root()
      assert.is_not_nil(root)

      local found_node, found_row = heading.find_section_matching(root, function()
        return false
      end)

      assert.is_nil(found_node)
      assert.is_nil(found_row)
    end)
  end)
end)

describe("markdown heading in file without h1", function()
  before_each(function()
    load_fixture("/markdown-h2s.md")
  end)

  describe(".heading_info", function()
    it("correctly identifies h2 at top of file", function()
      local info = heading.heading_info(1) -- ## First
      assert.equal("heading", info.type)
      assert.equal(2, info.level)
    end)
  end)

  describe(".get_section_bounds", function()
    it("returns correct bounds for h2 at top", function()
      local level, start_row, end_row = heading.get_section_bounds(1)
      assert.equal(2, level)
      assert.equal(1, start_row)
      assert.is_not_nil(end_row)
    end)
  end)
end)
