local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local confinement = require("treewalker.confinement")
local anchor = require("treewalker.anchor")
local tw = require("treewalker")

describe("confinement", function()
  before_each(function()
    load_fixture("/lua.lua")
  end)

  describe(".should_confine with scope_confined = false (default)", function()
    before_each(function()
      tw.setup({ scope_confined = false })
    end)

    it("returns false when scope_confined is disabled", function()
      vim.fn.cursor(22, 3) -- inside function
      local current = anchor.current()
      vim.fn.cursor(30, 1) -- outside function
      local candidate = anchor.current()
      local result = confinement.should_confine(current, candidate)
      assert.is_false(result)
    end)

    it("always returns false regardless of node relationship", function()
      vim.fn.cursor(22, 3)
      local current = anchor.current()
      vim.fn.cursor(1, 1)
      local candidate = anchor.current()
      local result = confinement.should_confine(current, candidate)
      assert.is_false(result)
    end)
  end)

  describe(".should_confine with scope_confined = true", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("returns true when candidate is outside current parent", function()
      vim.fn.cursor(132, 3) -- inside a for loop
      local current = anchor.current()
      local current_parent = current.node:parent()
      assert.is_not_nil(current_parent)

      -- Find a candidate that's definitely outside
      vim.fn.cursor(1, 1) -- top level
      local candidate = anchor.current()

      local result = confinement.should_confine(current, candidate)
      assert.is_true(result)
    end)

    it("returns false when candidate is within current parent", function()
      vim.fn.cursor(22, 3) -- first statement in function
      local current = anchor.current()

      -- Stay within same function
      vim.fn.cursor(23, 3) -- next statement in same function
      local candidate = anchor.current()

      -- Both should be children of same function
      local result = confinement.should_confine(current, candidate)
      assert.is_false(result)
    end)

    it("returns false when current has no parent", function()
      vim.fn.cursor(1, 1) -- top level
      local current = anchor.current()
      vim.fn.cursor(3, 1)
      local candidate = anchor.current()

      -- Top level nodes may not have meaningful parents
      local current_parent = current.node:parent()
      if not current_parent then
        local result = confinement.should_confine(current, candidate)
        assert.is_false(result)
      end
    end)
  end)

  describe(".should_confine with TSNode inputs", function()
    before_each(function()
      tw.setup({ scope_confined = true })
    end)

    it("accepts TSNode directly as input", function()
      vim.fn.cursor(22, 3)
      local current_node = vim.treesitter.get_node()
      assert.is_not_nil(current_node)

      vim.fn.cursor(1, 1)
      local candidate_node = vim.treesitter.get_node()
      assert.is_not_nil(candidate_node)

      -- Should not error with TSNode inputs
      local result = confinement.should_confine(current_node, candidate_node)
      assert.is_boolean(result)
    end)

    it("converts TSNode to anchor internally", function()
      vim.fn.cursor(132, 3)
      local current_node = vim.treesitter.get_node()
      assert.is_not_nil(current_node)

      vim.fn.cursor(1, 1)
      local candidate_node = vim.treesitter.get_node()
      assert.is_not_nil(candidate_node)

      local result = confinement.should_confine(current_node, candidate_node)
      assert.is_boolean(result)
    end)
  end)
end)

describe("confinement with nested structures", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ scope_confined = true })
  end)

  it("confines movement within for loops", function()
    vim.fn.cursor(132, 3) -- for loop start
    local current = anchor.current()

    -- Get something outside the loop
    vim.fn.cursor(128, 1) -- function declaration
    local candidate = anchor.current()

    local result = confinement.should_confine(current, candidate)
    assert.is_true(result)
  end)

  it("allows movement within same loop body", function()
    vim.fn.cursor(133, 5) -- inside for loop
    local current = anchor.current()

    vim.fn.cursor(134, 5) -- next line in same loop
    local candidate = anchor.current()

    local result = confinement.should_confine(current, candidate)
    assert.is_false(result)
  end)
end)

describe("confinement edge cases", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ scope_confined = true })
  end)

  it("handles sibling nodes correctly", function()
    vim.fn.cursor(1, 1) -- first top-level statement
    local current = anchor.current()

    vim.fn.cursor(3, 1) -- another top-level statement
    local candidate = anchor.current()

    -- Siblings at top level should not be confined
    local result = confinement.should_confine(current, candidate)
    assert.is_false(result)
  end)

  it("handles deeply nested nodes", function()
    vim.fn.cursor(149, 7) -- deeply nested
    local current = anchor.current()

    vim.fn.cursor(1, 1) -- top level
    local candidate = anchor.current()

    local result = confinement.should_confine(current, candidate)
    assert.is_true(result)
  end)
end)
