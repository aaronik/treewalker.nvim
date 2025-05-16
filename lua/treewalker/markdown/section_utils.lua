local markdown_line_utils = require "treewalker.markdown.line_utils"
local util = require "treewalker.util"

local classify_line = markdown_line_utils.classify_line

local M = {}

---@param row integer
---@return integer | nil, integer | nil, integer | nil
function M.get_markdown_section_bounds(row)
  if not util.is_markdown_file() then return nil, nil, nil end
  local info = classify_line(row)
  if info.type ~= "heading" then return nil, nil, nil end
  local level = info.level
  local start_row = row
  local end_row = nil
  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = row + 1, max_row do
    local next_info = classify_line(next_row)
    if next_info.type == "heading" and next_info.level <= level then
      end_row = next_row - 1
      break
    end
  end
  if not end_row then
    end_row = max_row
  end
  return level, start_row, end_row
end

function M.find_parent_header(row, level)
  for r = row - 1, 1, -1 do
    local info = classify_line(r)
    if info.type == "heading" and info.level < level then
      return r, info.level
    end
  end
  return nil, nil
end

function M.get_parent_section_bounds(row, level)
  local parent_row, parent_level = M.find_parent_header(row, level)
  if parent_row and parent_level then
    return M.get_markdown_section_bounds(parent_row)
  end
  return nil, 1, vim.api.nvim_buf_line_count(0)
end

return M
