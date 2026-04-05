local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local classify = require("treewalker.classify")

describe("classify", function()
  before_each(function()
    load_fixture("/lua.lua")
  end)

  describe(".is_jump_target", function()
    it("returns true for function nodes", function()
      vim.fn.cursor(21, 1) -- function line
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find the function_declaration or similar node
      while node and not node:type():match("function") do
        node = node:parent()
      end
      if node then
        assert.is_true(classify.is_jump_target(node))
      end
    end)

    it("returns false for comment nodes", function()
      vim.fn.cursor(195, 1) -- comment line at the bottom
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find comment node
      while node and not node:type():match("comment") do
        node = node:parent()
      end
      if node then
        assert.is_false(classify.is_jump_target(node))
      end
    end)

    it("returns true for variable declaration nodes", function()
      vim.fn.cursor(1, 1)
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find declaration node
      while node and not (node:type():match("declaration") or node:type():match("assignment")) do
        node = node:parent()
      end
      if node then
        assert.is_true(classify.is_jump_target(node))
      end
    end)

    it("returns false for root nodes", function()
      local root = vim.treesitter.get_parser():parse()[1]:root()
      assert.is_not_nil(root)
      assert.is_false(classify.is_jump_target(root))
    end)
  end)

  describe(".is_highlight_target", function()
    it("returns true for function nodes", function()
      vim.fn.cursor(21, 1)
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find the function node
      while node and not node:type():match("function") do
        node = node:parent()
      end
      if node then
        assert.is_true(classify.is_highlight_target(node))
      end
    end)

    it("returns false for block nodes", function()
      vim.fn.cursor(22, 3) -- inside function body
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find a block node
      while node and not node:type():match("block") do
        node = node:parent()
      end
      if node then
        assert.is_false(classify.is_highlight_target(node))
      end
    end)

    it("returns false for root nodes", function()
      local root = vim.treesitter.get_parser():parse()[1]:root()
      assert.is_not_nil(root)
      assert.is_false(classify.is_highlight_target(root))
    end)
  end)

  describe(".is_augment_target", function()
    it("returns true for comment nodes", function()
      vim.fn.cursor(195, 1) -- comment line
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find comment node
      while node and not node:type():match("comment") do
        node = node:parent()
      end
      if node then
        assert.is_true(classify.is_augment_target(node))
      end
    end)

    it("returns false for function nodes", function()
      vim.fn.cursor(21, 1)
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find function node
      while node and not node:type():match("function") do
        node = node:parent()
      end
      if node then
        assert.is_false(classify.is_augment_target(node))
      end
    end)

    it("returns false for root nodes", function()
      local root = vim.treesitter.get_parser():parse()[1]:root()
      assert.is_not_nil(root)
      assert.is_false(classify.is_augment_target(root))
    end)
  end)

  describe(".is_comment_node", function()
    it("returns true for comment nodes", function()
      vim.fn.cursor(195, 1) -- comment line
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Find comment node
      while node and not node:type():match("comment") do
        node = node:parent()
      end
      if node then
        assert.is_true(classify.is_comment_node(node))
      end
    end)

    it("returns false for non-comment nodes", function()
      vim.fn.cursor(1, 1) -- require line
      local node = vim.treesitter.get_node()
      assert.is_not_nil(node)
      -- Make sure we have a non-comment node
      while node and node:type():match("comment") do
        node = node:parent()
      end
      if node and not node:type():match("comment") and not node:type():match("source") and not node:type():match("text") then
        assert.is_false(classify.is_comment_node(node))
      end
    end)
  end)
end)

describe("classify with Python", function()
  before_each(function()
    load_fixture("/python.py")
  end)

  describe(".is_augment_target", function()
    it("returns true for decorator nodes", function()
      vim.fn.cursor(1, 1) -- Look for decorator
      local node = vim.treesitter.get_node()
      -- Traverse to find decorator
      local root = vim.treesitter.get_parser():parse()[1]:root()
      local function find_decorator(n)
        if n:type():match("decorat") then
          return n
        end
        for child in n:iter_children() do
          local found = find_decorator(child)
          if found then return found end
        end
        return nil
      end
      local decorator = find_decorator(root)
      if decorator then
        assert.is_true(classify.is_augment_target(decorator))
      end
    end)
  end)
end)

describe("classify with Rust", function()
  before_each(function()
    load_fixture("/rust.rs")
  end)

  describe(".is_augment_target", function()
    it("returns true for attribute_item nodes", function()
      local root = vim.treesitter.get_parser():parse()[1]:root()
      local function find_attribute(n)
        if n:type() == "attribute_item" then
          return n
        end
        for child in n:iter_children() do
          local found = find_attribute(child)
          if found then return found end
        end
        return nil
      end
      local attr = find_attribute(root)
      if attr then
        assert.is_true(classify.is_augment_target(attr))
      end
    end)
  end)
end)
