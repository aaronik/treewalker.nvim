local section_utils = require "treewalker.markdown.section_utils"
local sibling_utils = require "treewalker.markdown.sibling_utils"
local heading = require "treewalker.markdown.heading"
local util = require "treewalker.util"

local M = {}

-- Initial validation of the current and target sections
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@return table|nil section_info Information about the sections or nil if invalid
local function validate_section_basics(current_row, target_row)
  if not util.is_markdown_file() then return nil end

  local current_level, current_start, current_end = section_utils.get_markdown_section_bounds(current_row)
  if not current_level then return nil end

  local target_level, target_start, target_end = section_utils.get_markdown_section_bounds(target_row)
  if not target_level then return nil end

  if current_level ~= target_level then return nil end

  return {
    current_level = current_level,
    current_start = current_start,
    current_end = current_end,
    target_level = target_level,
    target_start = target_start,
    target_end = target_end
  }
end

-- Validate that both sections share the same parent
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@param level integer Level of both headings
---@return table|nil parent_info Information about the parent section or nil if invalid
local function validate_parent(current_row, target_row, level)
  local current_parent_row = section_utils.find_parent_header(current_row, level)
  local target_parent_row = section_utils.find_parent_header(target_row, level)

  local _, current_parent_start, current_parent_end =
      section_utils.get_parent_section_bounds(current_row, level)
  local _, target_parent_start, target_parent_end =
      section_utils.get_parent_section_bounds(target_row, level)

  if current_parent_row ~= target_parent_row then return nil end
  if current_parent_start ~= target_parent_start or current_parent_end ~= target_parent_end then return nil end

  return {
    row = current_parent_row,
    start = current_parent_start,
    finish = current_parent_end
  }
end

-- Validate that sections are properly contained within their parent (or global scope)
---@param current_start integer Start line of current section
---@param current_end integer End line of current section
---@param target_start integer Start line of target section
---@param target_end integer End line of target section
---@param parent table|nil Parent section information
---@return boolean is_valid Whether containment is valid
local function validate_containment(current_start, current_end, target_start, target_end, parent)
  if parent and parent.row ~= nil then
    return current_start >= parent.start and current_end <= parent.finish and
        target_start >= parent.start and target_end <= parent.finish
  else
    local global_start, global_end = 1, vim.api.nvim_buf_line_count(0)
    return current_start >= global_start and current_end <= global_end and
        target_start >= global_start and target_end <= global_end
  end
end

-- Validate that the sections are adjacent siblings
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@param level integer Level of both headings
---@param parent table Parent section information
---@return table|nil sibling_info Information about siblings or nil if invalid
local function validate_siblings(current_row, target_row, level, parent)
  local start_row = (parent.row == nil) and 1 or (parent.start + 1)
  local sibling_headers = sibling_utils.list_sibling_headers_of_level_in_bounds(
    level,
    parent.row,
    start_row,
    parent.finish
  )

  local current_idx, target_idx
  for i, v in ipairs(sibling_headers) do
    if v == current_row then current_idx = i end
    if v == target_row then target_idx = i end
  end

  if not current_idx or not target_idx then return nil end
  if math.abs(current_idx - target_idx) ~= 1 then return nil end

  return {
    siblings = sibling_headers,
    current_idx = current_idx,
    target_idx = target_idx
  }
end

-- Check that there are no intervening headings of equal or higher level
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@param level integer Level of both headings
---@return boolean is_valid Whether there are no prohibited intervening headings
local function validate_no_intervening_headings(current_row, target_row, level)
  local start_row = math.min(current_row, target_row)
  local end_row = math.max(current_row, target_row)

  for row = start_row + 1, end_row - 1 do
    local info = heading.heading_info(row)
    if info.type == "heading" and info.level <= level then
      return false
    end
  end

  return true
end

-- Collect and validate the context necessary for a heading swap.
-- Returns a table {current, target, parent, siblings} or nil if not swappable.
---@param current_row integer
---@param target_row integer
---@return table|nil
function M.get_validated_swap_context(current_row, target_row)
  -- Initial validation
  local section_info = validate_section_basics(current_row, target_row)
  if not section_info then return nil end

  -- Parent validation
  local parent_info = validate_parent(current_row, target_row, section_info.current_level)
  if not parent_info then return nil end

  -- Containment validation
  if not validate_containment(
        section_info.current_start, section_info.current_end,
        section_info.target_start, section_info.target_end,
        parent_info) then
    return nil
  end

  -- Sibling validation
  local sibling_info = validate_siblings(current_row, target_row, section_info.current_level, parent_info)
  if not sibling_info then return nil end

  -- Check for intervening headings
  if not validate_no_intervening_headings(current_row, target_row, section_info.current_level) then
    return nil
  end

  -- Construct the result
  return {
    current     = {
      row = current_row,
      level = section_info.current_level,
      start = section_info.current_start,
      finish = section_info.current_end
    },
    target      = {
      row = target_row,
      level = section_info.target_level,
      start = section_info.target_start,
      finish = section_info.target_end
    },
    parent      = parent_info,
    siblings    = sibling_info.siblings,
    current_idx = sibling_info.current_idx,
    target_idx  = sibling_info.target_idx,
  }
end

return M
