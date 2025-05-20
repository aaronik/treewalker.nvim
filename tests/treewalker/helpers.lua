local assert = require('luassert')
local stub = require 'luassert.stub'
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

  -- Let's always display something in the test output
  if expected_line == nil then
    expected_line = lines.get_line(expected_row)
  end

  assert(actual_line)
  assert(expected_line)

  -- Insert "|" character at specified column in each line
  actual_line = string.sub(actual_line, 1, actual_col - 1) .. "|" .. string.sub(actual_line, actual_col)
  expected_line = string.sub(expected_line, 1, expected_col - 1) .. "|" .. string.sub(expected_line, expected_col)

  -- It takes up too much room to show all the indentation
  actual_line = vim.fn.trim(actual_line)
  expected_line = vim.fn.trim(expected_line)

  -- Just in case the test fails
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
---@param lang string
M.ensure_has_parser = function(lang)
  local ok_given = pcall(vim.treesitter.get_parser, 0, lang)
  local ok_gotten = pcall(vim.treesitter.get_parser)

  local notify_once_stub = stub(vim, "notify_once")
  assert.stub(notify_once_stub).was.called(0)

  local ft = vim.bo.ft

  it(string.format("::The test suite has the [%s/%s] parser::", lang, ft), function()
    -- Three ways to check, this is the way implementation uses
    if not vim.treesitter.language.get_lang(lang) then
        error("Missing parser for: " .. lang)
    end

    if not ok_given then
      error(string.format("Test suite is missing parser for filetype [%s]", lang))
    end

    if not ok_gotten then
      error(string.format("Test suite is missing parser for filetype [%s]", ft))
    end
  end)
end

return M
