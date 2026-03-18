local nodes = require "treewalker.nodes"
local util = require "treewalker.util"
local targets = require "treewalker.targets"

local M = {}

---@param direction "find_up" | "find_down" | "find_in" | "find_out"
---@param current_node TSNode
---@param current_row integer
---@return TSNode | nil, integer | nil
function M.get_target(direction, current_node, current_row)
  if util.is_markdown_file() then
    local navigation = require "treewalker.markdown.navigation"
    return navigation[direction](current_row)
  end

  return targets[direction](current_node, current_row)
end

---@param node TSNode
---@param row integer
---@return Range4
function M.get_jump_range(node, row)
  if not util.is_markdown_file() then
    return nodes.range(node)
  end

  local markdown_heading = require "treewalker.markdown.heading"
  local _, section_start, section_end = markdown_heading.get_section_bounds(row)
  if section_start and section_end then
    return { section_start - 1, 0, section_end - 1, 1 }
  end

  return nodes.range(node)
end

---@return boolean
function M.is_swap_target_node()
  local node = vim.treesitter.get_node()
  if not node then return false end

  if util.is_markdown_file() then
    local markdown_heading = require "treewalker.markdown.heading"
    return markdown_heading.is_heading(vim.fn.line("."))
  end

  if not nodes.is_jump_target(node) then return false end
  if vim.fn.line('.') - 1 ~= node:range() then return false end
  return true
end

---@param direction "up" | "down"
---@return boolean
function M.handle_vertical_swap(direction)
  if not util.is_markdown_file() then
    return false
  end

  local markdown_swap = require "treewalker.markdown.swap.section"

  if direction == "up" then
    markdown_swap.swap_up_markdown()
  else
    markdown_swap.swap_down_markdown()
  end

  return true
end

return M
