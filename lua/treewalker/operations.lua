local nodes = require 'treewalker.nodes'
local lines = require 'treewalker.lines'
local util = require 'treewalker.util'
local heading = require 'treewalker.markdown.heading'

local M = {}

-- Move cursor to first non-whitespace character of current line, accounting for tabstop
-- This is a tabstop-independent alternative to vim.cmd("normal! ^")
function M.move_to_line_start()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  local line = lines.get_line(row)
  if line then
    local start_col = lines.get_start_col(line)
    -- Only move if not already at line start
    if col ~= start_col then
      -- Use vim.fn.cursor() instead of nvim_win_set_cursor() to avoid treesitter node caching issues in CI
      vim.fn.cursor(row, start_col)
    end
  end
end

-- Position cursor at first non-whitespace character of specified row
---@param row integer
function M.jump_to_line_start(row)
  local line = lines.get_line(row)
  if line then
    local start_col = lines.get_start_col(line)
    -- Use vim.fn.cursor() instead of nvim_win_set_cursor() to avoid treesitter node caching issues in CI
    vim.fn.cursor(row, start_col)
  else
    vim.fn.cursor(row, 1)
  end
end

-- For a potentially more nvim-y way to do it, see how treesitter-utils does it:
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/981ca7e353da6ea69eaafe4348fda5e800f9e1d8/lua/nvim-treesitter/ts_utils.lua#L388
-- (ts_utils.swap_nodes)

--- Swap two (inclusive) line ranges in the current buffer
-- The ranges may overlap or appear in any order. All indices are 1-based and inclusive.
function M.swap_buffer_ranges(start1, end1, start2, end2)
  if start1 > end1 or start2 > end2 then
    return false, 'Invalid range given'
  end
  -- Lua indices must be 0-based for nvim_buf_get/set_lines
  local lines1 = vim.api.nvim_buf_get_lines(0, start1 - 1, end1, false)
  local lines2 = vim.api.nvim_buf_get_lines(0, start2 - 1, end2, false)
  if #lines1 == 0 or #lines2 == 0 then
    return false, 'One or both ranges are empty'
  end
  local lines1copy = vim.deepcopy(lines1)
  local lines2copy = vim.deepcopy(lines2)
  if start1 > start2 then
    vim.api.nvim_buf_set_lines(0, start1 - 1, end1, false, lines2copy)
    vim.api.nvim_buf_set_lines(0, start2 - 1, end2, false, lines1copy)
  else
    vim.api.nvim_buf_set_lines(0, start2 - 1, end2, false, lines1copy)
    vim.api.nvim_buf_set_lines(0, start1 - 1, end1, false, lines2copy)
  end
  return true
end

---Create visual selection for the given range without moving cursor
---Good lord, why isn't there some API to do this? Someone should do something
---about that!
---@param range Range4
function M.select(range)
  local _, _, end_row, end_col = range[1], range[2], range[3], range[4]

  -- Exit visual mode if we're already in it to start fresh
  local current_mode = vim.fn.mode()
  if current_mode == 'v' or current_mode == 'V' or current_mode == '\22' then
    vim.cmd('normal! \\<Esc>')
  end

  -- Use current cursor position as start of selection
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor_pos[1]
  local start_col = cursor_pos[2]

  -- Convert 0-indexed range to 1-indexed for vim
  local end_line = end_row + 1

  -- Treesitter ranges are exclusive at the end, but vim visual selections are inclusive
  local adjusted_end_col = end_col > 0 and end_col - 1 or end_col

  -- Enter visual mode
  vim.cmd('normal! v')

  -- Move to end position
  vim.api.nvim_win_set_cursor(0, { end_line, adjusted_end_col })

  -- Exit and re-enter visual mode to ensure marks are set
  vim.cmd('normal! \\<Esc>')

  -- Set the marks manually to ensure they're correct
  vim.api.nvim_buf_set_mark(0, '<', start_line, start_col, {})
  vim.api.nvim_buf_set_mark(0, '>', end_line, adjusted_end_col, {})

  -- Re-enter visual mode using gv which restores the selection based on marks
  vim.cmd('normal! gv')

  -- Ensure cursor is at the start of the selection
  local new_cursor_pos = vim.api.nvim_win_get_cursor(0)
  if new_cursor_pos[1] ~= start_line or new_cursor_pos[2] ~= start_col then
    vim.cmd('normal! o')  -- Switch to other end of selection
  end
end

---Flash a highlight over the given range
---@param range Range4
---@param duration integer
---@param hl_group string
function M.highlight(range, duration, hl_group)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local ns_name = "treewalker.nvim-movement-highlight"
  local ns_id = vim.api.nvim_create_namespace(ns_name)

  -- clear any previous highlights so there aren't multiple active at the same time
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

  if vim.hl then
    -- vim.hl.range (Neovim 0.10+ replacement for nvim_buf_add_highlight)
    -- Has timeout option, but when it expires, _auto clears whole namespace_ for pete's sake
    vim.hl.range(
      0,
      ns_id,
      hl_group,
      { start_row, start_col },
      { end_row, end_col },
      { inclusive = true }
    )
  else
    -- support for lower versions of neovim
    for row = start_row, end_row do
      vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, row, 0, -1)
    end
  end

  -- Remove the local highlight after delay
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, start_row, end_row + 1)
  end, duration)
end

---@param node TSNode
---@param row integer
function M.jump(node, row)
  M.jump_to_line_start(row)
  local opts = require("treewalker").opts
  local range = nodes.range(node)

  if util.is_markdown_file() then
    local _, section_start, section_end = heading.get_section_bounds(row)
    if section_start and section_end then
      range = { section_start - 1, 0, section_end - 1, 1 }
    end
  end

  if opts.select then
    M.select(range)
  elseif opts.highlight then
    local duration = opts.highlight_duration
    local hl_group = opts.highlight_group
    M.highlight(range, duration, hl_group)
  end
end

-- Swap entire rows
---@param earlier_rows [integer, integer] -- [start row, end row]
---@param later_rows [integer, integer] -- [start row, end row]
function M.swap_rows(earlier_rows, later_rows)
  local earlier_start, earlier_end = earlier_rows[1], earlier_rows[2]
  local earlier_lines = lines.get_lines(earlier_start + 1, earlier_end + 1)
  local later_start, later_end = later_rows[1], later_rows[2]
  local later_lines = lines.get_lines(later_start + 1, later_end + 1)

  -- Collapse the later node
  lines.delete_lines(later_start + 1, later_end + 1) -- two plus ones works for deleting single and multiple lines

  -- Add earlier node to later slot
  lines.insert_lines(later_start, earlier_lines)

  -- Now collapse the earlier node
  lines.delete_lines(earlier_start + 1, earlier_end + 1)

  -- And add the later node to the earlier slot
  lines.insert_lines(earlier_start, later_lines)
end

-- Swap nodes. First goes to where second was, second goes to where first was.
---@param left TSNode
---@param right TSNode
function M.swap_nodes(left, right)
  local range1 = nodes.lsp_range(left)
  local range2 = nodes.lsp_range(right)

  local text1 = nodes.get_lines(left)
  local text2 = nodes.get_lines(right)

  local edit1 = { range = range1, newText = table.concat(text2, "\n") }
  local edit2 = { range = range2, newText = table.concat(text1, "\n") }
  local bufnr = vim.api.nvim_get_current_buf()
  local encoding = vim.api.nvim_get_option_value('fileencoding', {})
  if not encoding or encoding == "" then encoding = "utf-8" end -- #23
  vim.lsp.util.apply_text_edits({ edit1, edit2 }, bufnr, encoding)
end

return M
