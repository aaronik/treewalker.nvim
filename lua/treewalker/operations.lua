local nodes = require 'treewalker.nodes'
local lines = require 'treewalker.lines'

local M = {}

-- For a potentially more nvim-y way to do it, see how treesitter-utils does it:
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/981ca7e353da6ea69eaafe4348fda5e800f9e1d8/lua/nvim-treesitter/ts_utils.lua#L388
-- (ts_utils.swap_nodes)

---Flash a highlight over the given range
---@param range Range4
---@param duration integer
---@param hl_group string
function M.highlight(range, duration, hl_group)
  local start_row, _, end_row, _ = range[1], range[2], range[3], range[4]
  local ns_id = vim.api.nvim_create_namespace("")

  for row = start_row, end_row do
    vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, row, 0, -1)
  end

  -- Remove the highlight after delay
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    -- vim.api.nvim_buf_del_extmark(0, ns_id, start_mark)
  end, duration)
end

---@param node TSNode
---@param row integer
function M.jump(node, row)
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd("normal! ^")  -- Jump to start of line
  if require("treewalker").opts.highlight then
    local range = nodes.range(node)
    local duration = require("treewalker").opts.highlight_duration
    local hl_group = require("treewalker").opts.highlight_group
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


