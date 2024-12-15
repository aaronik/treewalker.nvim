local util = require('treewalker.util')
local nodes = require('treewalker.nodes')
local lines = require('treewalker.lines')

---@param row integer
---@param line string
---@param candidate TSNode
---@return nil
local function log(row, line, candidate)
  local col = lines.get_start_col(line)
  local log_string = "dest:"
  log_string = log_string .. string.format(" [%s/%s]", row, col)
  log_string = log_string .. string.format(" (%s)", candidate:type())
  log_string = log_string .. string.format(" |%s|", line)
  log_string = log_string .. string.format(" {%s}", vim.inspect(nodes.range(candidate)))
  util.log(log_string)
end

local M = {}

---Flash a highlight over the given range
---@param range Range4
---@param duration integer
function M.highlight(range, duration)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local ns_id = vim.api.nvim_create_namespace("")
  -- local hl_group = "DiffAdd"
  -- local hl_group = "MatchParen"
  -- local hl_group = "Search"
  local hl_group = "ColorColumn"

  for row = start_row, end_row do
    if row == start_row and row == end_row then
      -- Highlight within the same line
      vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, start_row, start_col, end_col)
    elseif row == start_row then
      -- Highlight from start_col to the end of the start_row
      vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, start_row, start_col, -1)
    elseif row == end_row then
      -- Highlight from the beginning of the end_row to end_col
      vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, end_row, 0, end_col)
    else
      -- Highlight the entire row for intermediate rows
      vim.api.nvim_buf_add_highlight(0, ns_id, hl_group, row, 0, -1)
    end
  end

  -- Remove the highlight after delay
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end, duration)
end

---@param row integer
---@param node TSNode
function M.jump(row, node)
  -- local line = lines.get_line(row)
  -- log(row, line, node)

  vim.cmd("normal! m'") -- Add originating node to jump list
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd("normal! ^")  -- Jump to start of line
  if require("treewalker").opts.highlight then
    local range = nodes.range(node)
    local duration = require("treewalker").opts.highlight_duration
    M.highlight(range, duration)
  end
end

---@param earlier_rows [integer, integer] -- [start row, end row]
---@param later_rows [integer, integer] -- [start row, end row]
function M.swap(earlier_rows, later_rows)
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

return M

---- Leaving this here for now because my gut says this is a better way to do it,
---- and at some point it may want to get done.
---- https://github.com/nvim-treesitter/nvim-treesitter/blob/981ca7e353da6ea69eaafe4348fda5e800f9e1d8/lua/nvim-treesitter/ts_utils.lua#L388
---- (ts_utils.swap_nodes)
-----@param rows1 [integer, integer] -- [start row, end row]
-----@param rows2 [integer, integer] -- [start row, end row]
--function M.swap(rows1, rows2)
--  local s1, e1, s2, e2 = rows1[1], rows1[2], rows2[1], rows2[2]
--  local text1 = lines.get_lines(s1 + 1, e1 + 1)
--  local text2 = lines.get_lines(s2 + 1, e2 + 1)

--  util.log("text1: " .. s1 .. "/" .. e1)
--  util.log("text2: " .. s2 .. "/" .. e2)

--  ---@type lsp.Range
--  local range1 = {
--    start = { line = s1, character = 0 },
--    ["end"] = { line = e1, character = 0 } -- end is reserved
--  }

--  ---@type lsp.Range
--  local range2 = {
--    start = { line = s2, character = 0 },
--    ["end"] = { line = e2 + 1, character = 0 }
--  }

--  -- util.log(range1, range2)

--  -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textEdit
--  lines.set_lines(s1 + 1, text2)
--  ---@type lsp.TextEdit
--  local edit1 = { range = range1, newText = table.concat(text2, "\n") }

--  lines.set_lines(s2 + 1, text1)
--  ---@type lsp.TextEdit
--  local edit2 = { range = range2, newText = table.concat(text1, "\n") }

--  local bufnr = vim.api.nvim_get_current_buf()
--  -- vim.lsp.util.apply_text_edits({ edit1, edit2 }, bufnr, "utf-8")
--end


