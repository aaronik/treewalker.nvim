local util = require('treewalker.util')
local nodes = require('treewalker.nodes')
local lines = require('treewalker.lines')

---@param row integer
---@param line string
---@param candidate TSNode
---@return nil
local function log(row, line, candidate)
  local col = lines.get_start_col(line)
  util.log(
    "dest: [L " ..
    row .. ", I " .. col .. "] |" .. line .. "| [" .. candidate:type() .. "]" .. vim.inspect(nodes.range(candidate))
  )
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

  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end, duration)
end

---@param row integer
---@param node TSNode
function M.jump(row, node)
  vim.cmd("normal! m'") -- Add originating node to jump list
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd("normal! ^")  -- Jump to start of line
  if require("treewalker").opts.highlight then
    node = nodes.get_highest_coincident(node)
    local range = nodes.range(node)
    local duration = require("treewalker").opts.highlight_duration
    M.highlight(range, duration)
  end
end

-- https://github.com/nvim-treesitter/nvim-treesitter/blob/981ca7e353da6ea69eaafe4348fda5e800f9e1d8/lua/nvim-treesitter/ts_utils.lua#L388
-- (ts_utils.swap_nodes)
---@param rows1 [integer, integer] -- [start row, end row]
---@param rows2 [integer, integer] -- [start row, end row]
function M.swap(rows1, rows2)
  local s1, e1, s2, e2 = rows1[1], rows1[2], rows2[1], rows2[2]
  local text1 = lines.get_lines(s1, e1)
  local text2 = lines.get_lines(s2, e2)

  ---@type lsp.Range
  local range1 = {
    start = { line = s1 - 1, character = 0 },
    ["end"] = { line = e1 - 1, character = 0 } -- end is reserved
  }

  ---@type lsp.Range
  local range2 = {
    start = { line = s2 - 1, character = 0 },
    ["end"] = { line = e2 - 1, character = 0 }
  }

  -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textEdit
  ---@type lsp.TextEdit
  local edit1 = { range = range1, newText = table.concat(text2, "\n") }
  ---@type lsp.TextEdit
  local edit2 = { range = range2, newText = table.concat(text1, "\n") }

  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.util.apply_text_edits({ edit1, edit2 }, bufnr, "utf-8")
end

return M
