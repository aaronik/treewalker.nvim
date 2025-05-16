-- Range-based operations for markdown buffers (primarily swapping, reusable across markdown logic)
local M = {}

--- Swap two (inclusive) line ranges in the current buffer
-- The ranges may overlap or appear in any order. All indices are 1-based and inclusive.
function M.swap_buffer_ranges(start1, end1, start2, end2)
  if start1 > end1 or start2 > end2 then
    return false, 'Invalid range given'
  end
  -- Lua indices must be 0-based for nvim_buf_get/set_lines
  local lines1 = vim.api.nvim_buf_get_lines(0, start1-1, end1, false)
  local lines2 = vim.api.nvim_buf_get_lines(0, start2-1, end2, false)
  if #lines1==0 or #lines2==0 then
    return false, 'One or both ranges are empty'
  end
  local lines1copy = vim.deepcopy(lines1)
  local lines2copy = vim.deepcopy(lines2)
  if start1 > start2 then
    vim.api.nvim_buf_set_lines(0, start1-1, end1, false, lines2copy)
    vim.api.nvim_buf_set_lines(0, start2-1, end2, false, lines1copy)
  else
    vim.api.nvim_buf_set_lines(0, start2-1, end2, false, lines1copy)
    vim.api.nvim_buf_set_lines(0, start1-1, end1, false, lines2copy)
  end
  return true
end

return M
