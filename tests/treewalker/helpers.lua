local M = {}

-- Assert the cursor is in the expected position
---@param line integer
---@param column integer
---@param msg string?
function M.assert_cursor_at(line, column, msg)
  local cursor_pos = vim.fn.getpos('.')
  ---@type integer, integer
  local current_line, current_column
  current_line, current_column = cursor_pos[2], cursor_pos[3]
  msg = string.format("expected to be at [%s] but wasn't", msg)
  assert.are.same({ line, column }, { current_line, current_column }, msg)
end

return M
