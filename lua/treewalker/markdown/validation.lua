local section_utils = require "treewalker.markdown.section_utils"
local sibling_utils = require "treewalker.markdown.sibling_utils"
local markdown_line_utils = require "treewalker.markdown.line_utils"
local util = require "treewalker.util"

local classify_line = markdown_line_utils.classify_line

local M = {}

---
-- Collect and validate the context necessary for a heading swap.
-- Returns a table {current, target, parent, siblings} or nil if not swappable.
---@param current_row integer
---@param target_row integer
---@return table|nil
function M.get_validated_swap_context(current_row, target_row)
  if not util.is_markdown_file() then return nil end
  local current_level, current_start, current_end = section_utils.get_markdown_section_bounds(current_row)
  if not current_level then return nil end
  local target_level, target_start, target_end = section_utils.get_markdown_section_bounds(target_row)
  if not target_level then return nil end
  if current_level ~= target_level then return nil end
  local current_parent_row = section_utils.find_parent_header(current_row, current_level)
  local target_parent_row = section_utils.find_parent_header(target_row, target_level)
  local _, current_parent_start, current_parent_end =
    section_utils.get_parent_section_bounds(current_row, current_level)
  local _, target_parent_start, target_parent_end = section_utils.get_parent_section_bounds(target_row, target_level)
  if current_parent_row ~= target_parent_row then return nil end
  if current_parent_start ~= target_parent_start or current_parent_end ~= target_parent_end then return nil end
  if current_parent_row ~= nil then
    if not (
          current_start >= current_parent_start and current_end <= current_parent_end and
          target_start >= current_parent_start and target_end <= current_parent_end
        ) then
      return nil
    end
  else
    local global_start, global_end = 1, vim.api.nvim_buf_line_count(0)
    if not (
          current_start >= global_start and current_end <= global_end and
          target_start >= global_start and target_end <= global_end
        ) then
      return nil
    end
  end
  local sibling_headers = sibling_utils.list_sibling_headers_of_level_in_bounds(current_level, current_parent_row,
    current_parent_start + 1, current_parent_end)
  local current_idx, target_idx
  for i, v in ipairs(sibling_headers) do
    if v == current_row then current_idx = i end
    if v == target_row then target_idx = i end
  end
  if not current_idx or not target_idx then return nil end
  if math.abs(current_idx - target_idx) ~= 1 then return nil end
  if current_row < target_row then
    for row = current_row + 1, target_row - 1 do
      local info = classify_line(row)
      if info.type == "heading" and info.level <= current_level then
        return nil
      end
    end
  else
    for row = target_row + 1, current_row - 1 do
      local info = classify_line(row)
      if info.type == "heading" and info.level <= current_level then
        return nil
      end
    end
  end
  return {
    current = {row = current_row, level = current_level, start = current_start, finish = current_end},
    target  = {row = target_row, level = target_level, start = target_start, finish = target_end},
    parent  = {row = current_parent_row, start = current_parent_start, finish = current_parent_end},
    siblings = sibling_headers,
    current_idx = current_idx,
    target_idx = target_idx,
  }
end

return M
