-- Navigation strategy dispatcher for markdown
-- This is a refactored delegator: each movement direction is a small focused module.
local find_out = require "treewalker.markdown.navigation.find_out"
local find_in = require "treewalker.markdown.navigation.find_in"
local find_up = require "treewalker.markdown.navigation.find_up"
local find_down = require "treewalker.markdown.navigation.find_down"

local M = {}

function M.find_out(current_row)
  return find_out(current_row)
end

function M.find_in(current_row)
  return find_in(current_row)
end

function M.find_up(current_row)
  return find_up(current_row)
end

function M.find_down(current_row)
  return find_down(current_row)
end

return M
