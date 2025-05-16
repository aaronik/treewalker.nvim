local strategy = require "treewalker.markdown.navigation_strategy"

local M = {}

function M.out()
  local current_row = vim.fn.line(".")
  return strategy.find_out(current_row)
end

function M.inn()
  local current_row = vim.fn.line(".")
  return strategy.find_in(current_row)
end

function M.up()
  local current_row = vim.fn.line(".")
  return strategy.find_up(current_row)
end

function M.down()
  local current_row = vim.fn.line(".")
  return strategy.find_down(current_row)
end

return M
