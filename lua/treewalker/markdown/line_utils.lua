-- luacheck: globals vim
local util = require "treewalker.util"
local lines = require "treewalker.lines"
local M = {}

--- Classifies a markdown line based on what kind of line it is.
-- { type = "heading", level = N }
-- { type = "none" }
---@param row integer
---@return table
function M.classify_line(row)
  if not row then return { type = "none" } end
  if not util.is_markdown_file() then return { type = "none" } end
  local line = lines.get_line(row)
  if not line then return { type = "none" } end
  local level_match = line:match("^(#+)%s")
  if level_match then
    return { type = "heading", level = #level_match }
  end
  return { type = "none" }
end

return M
