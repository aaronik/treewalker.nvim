-- Markdown navigation targets: moves the cursor through the Markdown tree.
local navigation = require "treewalker.markdown.navigation"

local M = {}

--- Move outward (to parent heading)
function M.out()
  local current_row = vim.fn.line(".")
  return navigation.find_out(current_row)
end

--- Move inward (to first child heading, or remain on current)
function M.inn()
  local current_row = vim.fn.line(".")
  return navigation.find_in(current_row)
end

--- Move up (to previous sibling heading or nearest previous heading)
function M.up()
  local current_row = vim.fn.line(".")
  return navigation.find_up(current_row)
end

--- Move down (to next sibling heading or nearest next heading)
function M.down()
  local current_row = vim.fn.line(".")
  return navigation.find_down(current_row)
end

return M
