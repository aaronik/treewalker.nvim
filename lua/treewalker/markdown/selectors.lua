local util = require "treewalker.util"
local heading = require "treewalker.markdown.heading"
local heading_search = require "treewalker.markdown.heading_search"

local M = {}

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then return nil, nil end
  local current_level = heading.heading_level(row)
  return heading_search.find_heading(row, {
    dir = 1,
    matcher = function(_, check_row)
      return heading.is_heading(check_row) and heading.heading_level(check_row) == current_level
    end,
  })
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then
    return M.get_nearest_prev_heading(row)
  end
  local current_level = heading.heading_level(row)
  return heading_search.find_heading(row, {
    dir = -1,
    matcher = function(_, check_row)
      return heading.is_heading(check_row) and heading.heading_level(check_row) == current_level
    end,
  })
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_prev_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  return heading_search.find_heading(row, {
    dir = -1,
    matcher = function(_, check_row)
      return heading.is_heading(check_row)
    end,
  })
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_next_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  return heading_search.find_heading(row, {
    dir = 1,
    matcher = function(_, check_row)
      return heading.is_heading(check_row)
    end,
  })
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_inner_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then return nil, nil end
  local current_level = heading.heading_level(row)
  local target_level = current_level + 1
  local stopped_on_out = false
  local node, found_row = heading_search.find_heading(row, {
    dir = 1,
    matcher = function(_, check_row)
      if not heading.is_heading(check_row) then return false end
      local l = heading.heading_level(check_row)
      if l == target_level then return true end
      if l <= current_level then
        stopped_on_out = true
        return false
      end
      return false
    end,
  })
  if stopped_on_out then return nil, nil end
  return node, found_row
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_outer_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) or heading.heading_level(row) <= 1 then return nil, nil end
  local target_level = heading.heading_level(row) - 1
  return heading_search.find_heading(row, {
    dir = -1,
    matcher = function(_, check_row)
      return heading.is_heading(check_row) and heading.heading_level(check_row) == target_level
    end,
  })
end

return M
