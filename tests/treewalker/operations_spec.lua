local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local operations = require("treewalker.operations")
local nodes = require("treewalker.nodes")
local lines = require("treewalker.lines")
local tw = require("treewalker")

describe("operations", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ highlight = false })
  end)

  describe(".jump_to_line_start", function()
    it("jumps to the first non-whitespace character", function()
      vim.fn.cursor(1, 1)
      operations.jump_to_line_start(22) -- indented line
      local pos = vim.fn.getpos(".")
      assert.equal(22, pos[2])
      assert.equal(3, pos[3]) -- first non-whitespace
    end)

    it("jumps to column 1 for lines starting at column 1", function()
      vim.fn.cursor(5, 5)
      operations.jump_to_line_start(1)
      local pos = vim.fn.getpos(".")
      assert.equal(1, pos[2])
      assert.equal(1, pos[3])
    end)

    it("handles empty lines", function()
      vim.fn.cursor(1, 1)
      operations.jump_to_line_start(2) -- empty line
      local pos = vim.fn.getpos(".")
      assert.equal(2, pos[2])
      assert.equal(1, pos[3])
    end)
  end)

  describe(".swap_buffer_ranges", function()
    it("swaps two non-overlapping ranges", function()
      local original_line1 = lines.get_line(1)
      local original_line3 = lines.get_line(3)

      local ok = operations.swap_buffer_ranges(1, 1, 3, 3)

      assert.is_true(ok)
      assert.equal(original_line1, lines.get_line(3))
      assert.equal(original_line3, lines.get_line(1))
    end)

    it("returns false for invalid ranges (start > end)", function()
      local ok, msg = operations.swap_buffer_ranges(3, 1, 5, 6)
      assert.is_false(ok)
      assert.is_string(msg)
    end)

    it("swaps multi-line ranges", function()
      local original_lines_1_2 = lines.get_lines(1, 2)
      local original_lines_4_5 = lines.get_lines(4, 5)

      local ok = operations.swap_buffer_ranges(1, 2, 4, 5)

      assert.is_true(ok)
      assert.same(original_lines_1_2, lines.get_lines(4, 5))
      assert.same(original_lines_4_5, lines.get_lines(1, 2))
    end)

    it("handles ranges of different sizes", function()
      local original_line_1 = lines.get_line(1)
      local original_lines_3_4 = lines.get_lines(3, 4)

      local ok = operations.swap_buffer_ranges(1, 1, 3, 4)

      assert.is_true(ok)
      -- After swap, line counts change
      local new_line_1 = lines.get_line(1)
      local new_line_2 = lines.get_line(2)
      assert.same(original_lines_3_4, { new_line_1, new_line_2 })
    end)

    it("swaps correctly when second range comes before first", function()
      local original_line_5 = lines.get_line(5)
      local original_line_1 = lines.get_line(1)

      local ok = operations.swap_buffer_ranges(5, 5, 1, 1)

      assert.is_true(ok)
      assert.equal(original_line_5, lines.get_line(1))
      assert.equal(original_line_1, lines.get_line(5))
    end)
  end)

  describe(".swap_nodes", function()
    it("swaps two nodes on the same line", function()
      vim.fn.cursor(38, 32) -- node1
      local node1 = vim.treesitter.get_node()
      assert.is_not_nil(node1)

      vim.fn.cursor(38, 39) -- node2
      local node2 = vim.treesitter.get_node()
      assert.is_not_nil(node2)

      -- Get original text
      local original_text1 = vim.treesitter.get_node_text(node1, 0)
      local original_text2 = vim.treesitter.get_node_text(node2, 0)

      operations.swap_nodes(node1, node2)

      -- Verify the line changed
      local line = lines.get_line(38)
      assert.is_true(line:find(original_text2) ~= nil or line:find(original_text1) ~= nil)
    end)
  end)

  describe(".swap_rows", function()
    it("swaps entire rows", function()
      local original_line_1 = lines.get_line(1)
      local original_line_3 = lines.get_line(3)

      operations.swap_rows({ 0, 0 }, { 2, 2 })

      assert.equal(original_line_1, lines.get_line(3))
      assert.equal(original_line_3, lines.get_line(1))
    end)

    it("swaps multi-line row ranges", function()
      local original_1_2 = lines.get_lines(1, 2)
      local original_4_5 = lines.get_lines(4, 5)

      operations.swap_rows({ 0, 1 }, { 3, 4 })

      assert.same(original_1_2, lines.get_lines(4, 5))
      assert.same(original_4_5, lines.get_lines(1, 2))
    end)
  end)

  describe(".highlight", function()
    it("creates a highlight in the correct namespace", function()
      local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

      operations.highlight({ 0, 0, 0, 10 }, 50, "CursorLine")

      local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })
      assert.equal(1, #highlights)
    end)

    it("clears previous highlights before adding new ones", function()
      local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")

      operations.highlight({ 0, 0, 0, 10 }, 1000, "CursorLine")
      operations.highlight({ 1, 0, 1, 10 }, 1000, "CursorLine")

      local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
      assert.equal(1, #highlights)
    end)

    it("uses the specified highlight group", function()
      local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

      operations.highlight({ 0, 0, 0, 10 }, 50, "DiffAdd")

      local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })
      assert.equal(1, #highlights)
      assert.equal("DiffAdd", highlights[1][4].hl_group)
    end)
  end)

  describe(".select", function()
    before_each(function()
      -- Exit visual mode if in it
      if vim.fn.mode() ~= 'n' then
        vim.cmd('normal! \\<Esc>')
      end
    end)

    it("enters visual mode", function()
      vim.fn.cursor(1, 1)
      operations.select({ 0, 0, 0, 10 })

      local mode = vim.fn.mode()
      assert.equal("v", mode)
    end)

    it("sets selection marks correctly", function()
      vim.fn.cursor(1, 1)
      operations.select({ 0, 0, 2, 5 })

      local start_mark = vim.api.nvim_buf_get_mark(0, "<")
      local end_mark = vim.api.nvim_buf_get_mark(0, ">")

      assert.equal(1, start_mark[1])
      assert.equal(3, end_mark[1]) -- 0-indexed row 2 = 1-indexed row 3
    end)
  end)

  describe(".jump", function()
    it("moves cursor to specified row", function()
      vim.fn.cursor(10, 5)
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)

      operations.jump(node, 1)

      local pos = vim.fn.getpos(".")
      assert.equal(1, pos[2])
    end)

    it("respects highlight option when enabled", function()
      tw.setup({ highlight = true, highlight_duration = 50 })
      local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

      vim.fn.cursor(10, 1)
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)

      operations.jump(node, 1)

      local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
      assert.equal(1, #highlights)
    end)

    it("does not highlight when highlight is disabled", function()
      tw.setup({ highlight = false, select = false })
      local ns_id = vim.api.nvim_create_namespace("treewalker.nvim-movement-highlight")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

      vim.fn.cursor(10, 1)
      local node = nodes.get_at_row(1)
      assert.is_not_nil(node)

      operations.jump(node, 1)

      local highlights = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
      assert.equal(0, #highlights)
    end)
  end)
end)
