local assert = require('luassert')
local lines  = require('treewalker.lines')

local M      = {}

-- Assert the cursor is in the expected position
---@param expected_row integer
---@param expected_col integer
---@param expected_line string?
function M.assert_cursor_at(expected_row, expected_col, expected_line)
  local cursor_pos = vim.fn.getpos('.')
  local actual_row, actual_col = cursor_pos[2], cursor_pos[3]
  local actual_line = lines.get_line(actual_row)
  local error_line = string.format(
    "expected to be at [%s/%s](%s) but was at [%s/%s](%s)",
    expected_row, expected_col, expected_line, actual_row, actual_col, actual_line
  )
  assert.same({ expected_row, expected_col }, { actual_row, actual_col }, error_line)
end

-- Feed keys to neovim; keys are pressed no matter what vim mode or state
---@param keys string
---@return nil
M.feed_keys = function(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, true, true)
  vim.api.nvim_feedkeys(termcodes, 'mtx', false)
end

-- This is more for the test suite itself and ensuring that it's operating correctly.
-- Makes sure there's no missing parser for the loaded file in the current buffer
M.ensure_has_parser = function()
  it("the test suite has the parser for the requested filetype", function()
    local ok = pcall(vim.treesitter.get_parser)
    if not ok then
      error(string.format("Test suite is missing parser for ft [%s]", vim.bo.ft))
    end
  end)
end

return M
