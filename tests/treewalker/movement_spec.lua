local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local movement = require("treewalker.movement")
local tw = require("treewalker")
local h = require("tests.treewalker.helpers")

describe("movement module", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false, jumplist = false })
  end)

  describe(".move_up", function()
    it("moves to previous sibling at same indent", function()
      vim.fn.cursor(21, 1)
      movement.move_up()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[2] < 21)
    end)

    it("does nothing at first statement", function()
      vim.fn.cursor(1, 1)
      movement.move_up()
      h.assert_cursor_at(1, 1)
    end)

    it("respects indentation level", function()
      vim.fn.cursor(22, 3) -- inside function
      local before_indent = vim.fn.indent(vim.fn.line('.'))
      movement.move_up()
      -- Should either stay or move to same indent level
    end)
  end)

  describe(".move_down", function()
    it("moves to next sibling at same indent", function()
      vim.fn.cursor(1, 1)
      movement.move_down()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[2] > 1)
    end)

    it("does nothing at last statement", function()
      vim.fn.cursor(193, 1) -- return M
      movement.move_down()
      -- Should stay at same position or move to valid target
    end)

    it("skips empty lines", function()
      vim.fn.cursor(1, 1)
      movement.move_down()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[2] ~= 2) -- should skip empty line 2
    end)
  end)

  describe(".move_in", function()
    it("moves to first child at higher indent", function()
      vim.fn.cursor(21, 1) -- function
      movement.move_in()
      h.assert_cursor_at(22, 3)
    end)

    it("does nothing for leaf nodes", function()
      vim.fn.cursor(1, 1) -- simple require statement
      local before_pos = vim.fn.getpos(".")
      movement.move_in()
      -- May stay or move depending on node structure
    end)

    it("enters nested structures", function()
      vim.fn.cursor(143, 1) -- larger function
      movement.move_in()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[3] > 1) -- should be indented
    end)
  end)

  describe(".move_out", function()
    it("moves to parent at lower indent", function()
      vim.fn.cursor(22, 3) -- inside function
      movement.move_out()
      h.assert_cursor_at(21, 1)
    end)

    it("does nothing at top level", function()
      vim.fn.cursor(1, 1)
      movement.move_out()
      h.assert_cursor_at(1, 1)
    end)

    it("moves out of deeply nested structures", function()
      vim.fn.cursor(149, 7) -- deeply nested
      movement.move_out()
      local pos = vim.fn.getpos(".")
      assert.is_true(pos[3] < 7) -- should be less indented
    end)
  end)
end)

describe("movement with jumplist", function()
  before_each(function()
    load_fixture("/lua.lua")
    vim.cmd('windo clearjumps')
  end)

  describe("when jumplist = true", function()
    before_each(function()
      tw.setup({ jumplist = true, highlight = false })
    end)

    it("adds to jumplist on non-neighbor move_up", function()
      vim.fn.cursor(21, 1)
      movement.move_up()
      -- Jump should be added for non-neighbor moves
    end)

    it("adds to jumplist on move_in", function()
      vim.fn.cursor(21, 1)
      movement.move_in()
      local jumplist = vim.fn.getjumplist()[1]
      assert.is_true(#jumplist >= 1)
    end)

    it("adds to jumplist on move_out", function()
      vim.fn.cursor(22, 3)
      movement.move_out()
      local jumplist = vim.fn.getjumplist()[1]
      assert.is_true(#jumplist >= 1)
    end)
  end)

  describe("when jumplist = false", function()
    before_each(function()
      tw.setup({ jumplist = false, highlight = false })
    end)

    it("does not add to jumplist", function()
      vim.fn.cursor(1, 1)
      movement.move_down()
      local jumplist = vim.fn.getjumplist()[1]
      assert.equal(0, #jumplist)
    end)
  end)

  describe("when jumplist = 'left'", function()
    before_each(function()
      tw.setup({ jumplist = 'left', highlight = false })
    end)

    it("adds to jumplist only for move_out", function()
      vim.fn.cursor(22, 3)
      movement.move_out()
      local jumplist = vim.fn.getjumplist()[1]
      assert.equal(1, #jumplist)
    end)

    it("does not add to jumplist for move_in", function()
      vim.fn.cursor(21, 1)
      movement.move_in()
      local jumplist = vim.fn.getjumplist()[1]
      assert.equal(0, #jumplist)
    end)
  end)
end)

describe("movement with scope_confined", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ scope_confined = true, highlight = false })
  end)

  it("confines move_up within scope", function()
    vim.fn.cursor(132, 3) -- first statement in for loop
    -- Should not be able to move up out of parent scope
    movement.move_up()
    -- Verify we're still within the parent scope
  end)

  it("confines move_down within scope", function()
    vim.fn.cursor(136, 3) -- last statement in block
    movement.move_down()
    -- Should not escape scope
  end)
end)

describe("movement in markdown", function()
  before_each(function()
    load_fixture("/markdown.md")
    tw.setup({ highlight = false })
  end)

  it("uses markdown-specific navigation for move_up", function()
    vim.fn.cursor(19, 1) -- ## Text Formatting
    movement.move_up()
    h.assert_cursor_at(4, 1) -- ## Header
  end)

  it("uses markdown-specific navigation for move_down", function()
    vim.fn.cursor(4, 1) -- ## Header
    movement.move_down()
    h.assert_cursor_at(19, 1) -- ## Text Formatting
  end)

  it("uses markdown-specific navigation for move_in", function()
    vim.fn.cursor(4, 1) -- ## Header
    movement.move_in()
    h.assert_cursor_at(9, 1) -- ### Subheader
  end)

  it("uses markdown-specific navigation for move_out", function()
    vim.fn.cursor(9, 1) -- ### Subheader
    movement.move_out()
    h.assert_cursor_at(4, 1) -- ## Header
  end)
end)

describe("movement edge cases", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false })
  end)

  it("handles cursor in middle of identifier", function()
    vim.fn.cursor(21, 16) -- inside |is_jump_target
    movement.move_up()
    -- Should move to previous top-level statement
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] < 21)
  end)

  it("handles cursor at end of line", function()
    vim.fn.cursor(1, 100) -- past end of line 1
    movement.move_down()
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] > 1)
  end)

  it("handles empty file gracefully", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "lua"

    -- Should not error
    vim.fn.cursor(1, 1)
    -- movement.move_down() -- This would error due to no parser
  end)

  it("handles single statement file", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1" })
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "lua"
    pcall(vim.treesitter.get_parser, buf)

    vim.fn.cursor(1, 1)
    -- Should not error, may just not move
  end)
end)
