local assert = require("luassert")
local stub = require("luassert.stub")
local load_fixture = require("tests.load_fixture")
local tw = require("treewalker")
local h = require("tests.treewalker.helpers")

describe("treewalker init", function()
  describe(".setup", function()
    it("accepts nil without error", function()
      tw.setup(nil)
      assert.is_true(tw.opts.highlight)
    end)

    it("accepts empty table without error", function()
      tw.setup({})
      assert.is_true(tw.opts.highlight)
    end)

    it("merges options with defaults", function()
      tw.setup({ highlight = false })
      assert.is_false(tw.opts.highlight)
      assert.equal(250, tw.opts.highlight_duration) -- default preserved
    end)

    it("preserves all default options when not overridden", function()
      tw.setup({})
      assert.is_true(tw.opts.highlight)
      assert.equal(250, tw.opts.highlight_duration)
      assert.equal("CursorLine", tw.opts.highlight_group)
      assert.is_true(tw.opts.jumplist)
      assert.is_false(tw.opts.select)
      assert.is_true(tw.opts.notifications)
      assert.is_false(tw.opts.scope_confined)
    end)

    it("accepts all valid option combinations", function()
      tw.setup({
        highlight = true,
        highlight_duration = 100,
        highlight_group = "DiffAdd",
        jumplist = 'left',
        select = true,
        notifications = false,
        scope_confined = true,
      })
      assert.is_true(tw.opts.highlight)
      assert.equal(100, tw.opts.highlight_duration)
      assert.equal("DiffAdd", tw.opts.highlight_group)
      assert.equal('left', tw.opts.jumplist)
      assert.is_true(tw.opts.select)
      assert.is_false(tw.opts.notifications)
      assert.is_true(tw.opts.scope_confined)
    end)
  end)

  describe("ensuring_parser wrapper", function()
    it("returns false and notifies when parser is missing", function()
      load_fixture("/random.not_real", true) -- withhold parsing

      local notify_once_stub = stub.new(vim, "notify_once")

      tw.setup({ notifications = true })
      local result = tw.move_down()

      assert.is_false(result)
      assert.stub(notify_once_stub).was.called(1)

      notify_once_stub:revert()
    end)

    it("does not notify when notifications are disabled", function()
      load_fixture("/random.not_real", true)

      local notify_once_stub = stub.new(vim, "notify_once")

      tw.setup({ notifications = false })
      local result = tw.move_down()

      assert.is_false(result)
      assert.stub(notify_once_stub).was.called(0)

      notify_once_stub:revert()
    end)

    it("returns true when parser is available", function()
      load_fixture("/lua.lua")
      tw.setup({})
      vim.fn.cursor(1, 1)
      local result = tw.move_down()
      assert.is_true(result)
    end)
  end)

  describe("movement functions", function()
    before_each(function()
      load_fixture("/lua.lua")
      tw.setup({ highlight = false })
    end)

    it("move_up is callable and returns boolean", function()
      vim.fn.cursor(10, 1)
      local result = tw.move_up()
      assert.is_boolean(result)
    end)

    it("move_down is callable and returns boolean", function()
      vim.fn.cursor(1, 1)
      local result = tw.move_down()
      assert.is_boolean(result)
    end)

    it("move_in is callable and returns boolean", function()
      vim.fn.cursor(21, 1)
      local result = tw.move_in()
      assert.is_boolean(result)
    end)

    it("move_out is callable and returns boolean", function()
      vim.fn.cursor(22, 3)
      local result = tw.move_out()
      assert.is_boolean(result)
    end)
  end)

  describe("swap functions", function()
    before_each(function()
      load_fixture("/lua.lua")
      tw.setup({ highlight = false })
    end)

    it("swap_up is callable and returns boolean", function()
      vim.fn.cursor(21, 1)
      local result = tw.swap_up()
      assert.is_boolean(result)
    end)

    it("swap_down is callable and returns boolean", function()
      vim.fn.cursor(1, 1)
      local result = tw.swap_down()
      assert.is_boolean(result)
    end)

    it("swap_left is callable and returns boolean", function()
      vim.fn.cursor(38, 39)
      local result = tw.swap_left()
      assert.is_boolean(result)
    end)

    it("swap_right is callable and returns boolean", function()
      vim.fn.cursor(38, 32)
      local result = tw.swap_right()
      assert.is_boolean(result)
    end)
  end)
end)

describe("treewalker with unsupported filetypes", function()
  it("does not swap in text files", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "text"

    tw.setup({})
    vim.fn.cursor(2, 1)

    local lines_before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    tw.swap_down()
    local lines_after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    assert.same(lines_before, lines_after)
  end)

  it("does not swap in txt files", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "txt"

    tw.setup({})
    vim.fn.cursor(2, 1)

    local lines_before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    tw.swap_up()
    local lines_after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    assert.same(lines_before, lines_after)
  end)
end)

describe("treewalker edge cases", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false })
  end)

  it("handles cursor at end of file", function()
    h.feed_keys("G")
    -- Should not error
    tw.move_down()
    tw.move_in()
  end)

  it("handles cursor at beginning of file", function()
    vim.fn.cursor(1, 1)
    -- Should not error
    tw.move_up()
    tw.move_out()
  end)

  it("handles repeated movements in same direction", function()
    vim.fn.cursor(1, 1)
    for _ = 1, 10 do
      tw.move_down()
    end
    -- Should not error and should be somewhere in file
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] > 1)
  end)

  it("handles mixed movement directions", function()
    vim.fn.cursor(21, 1)
    tw.move_in()
    tw.move_down()
    tw.move_up()
    tw.move_out()
    -- Should not error
    local pos = vim.fn.getpos(".")
    assert.is_true(pos[2] >= 1)
  end)
end)
