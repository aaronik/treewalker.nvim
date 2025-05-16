local util = require "treewalker.util"

local M = {}

--- Returns true if the cursor is on a heading node in markdown.
---@return boolean
function M.is_on_markdown_heading()
  if not util.is_markdown_file() then return false end
  local row = vim.fn.line(".")
  local classify_line = require("treewalker.markdown.line_utils").classify_line
  local info = classify_line(row)
  return info.type == "heading"
end

return M
