local ops = require "treewalker.operations"
local markdown_targets = require "treewalker.markdown.targets"
local heading = require "treewalker.markdown.heading"
local util = require "treewalker.util"

local M = {}

-- List sibling headers of a given level and parent within a buffer range
---@param level integer
---@param parent_row integer|nil
---@param start_row integer
---@param end_row integer
---@return integer[]
local function list_sibling_headers_of_level_in_bounds(level, parent_row, start_row, end_row)
  local result = {}
  for row = start_row, end_row do
    local info = heading.heading_info(row)
    if info.type == "heading" and info.level == level then
      local this_parent_row, _ = heading.find_parent_header(row, info.level)
      if this_parent_row == parent_row then
        table.insert(result, row)
      end
    end
  end
  return result
end

-- Initial validation of the current and target sections
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@return table|nil section_info Information about the sections or nil if invalid
local function validate_section_basics(current_row, target_row)
  if not util.is_markdown_file() then return nil end

  local current_level, current_start, current_end = heading.get_section_bounds(current_row)
  if not current_level then return nil end

  local target_level, target_start, target_end = heading.get_section_bounds(target_row)
  if not target_level then return nil end

  if current_level ~= target_level then return nil end

  return {
    current_level = current_level,
    current_start = current_start,
    current_end = current_end,
    target_level = target_level,
    target_start = target_start,
    target_end = target_end,
  }
end

-- Validate that both sections share the same parent
---@param current_row integer Row number of the current heading
---@param target_row integer Row number of the target heading
---@param level integer Level of both headings
---@return table|nil parent_info Information about the parent section or nil if invalid
local function validate_parent(current_row, target_row, level)
  local current_parent_row = heading.find_parent_header(current_row, level)
  local target_parent_row = heading.find_parent_header(target_row, level)

  local _, current_parent_start, current_parent_end =
      heading.get_parent_section_bounds(current_row, level)
  local _, target_parent_start, target_parent_end =
      heading.get_parent_section_bounds(target_row, level)

  if current_parent_row ~= target_parent_row then return nil end
  if current_parent_start ~= target_parent_start or current_parent_end ~= target_parent_end then return nil end

  return {
    row = current_parent_row,
    start = current_parent_start,
    finish = current_parent_end,
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
  local sibling_headers = list_sibling_headers_of_level_in_bounds(
    level,
    parent.row,
    start_row,
    parent.finish
  )

  local current_idx, target_idx
  for i, value in ipairs(sibling_headers) do
    if value == current_row then current_idx = i end
    if value == target_row then target_idx = i end
  end

  if not current_idx or not target_idx then return nil end
  if math.abs(current_idx - target_idx) ~= 1 then return nil end

  return {
    siblings = sibling_headers,
    current_idx = current_idx,
    target_idx = target_idx,
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
local function get_validated_swap_context(current_row, target_row)
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
    current = {
      row = current_row,
      level = section_info.current_level,
      start = section_info.current_start,
      finish = section_info.current_end,
    },
    target = {
      row = target_row,
      level = section_info.target_level,
      start = section_info.target_start,
      finish = section_info.target_end,
    },
    parent = parent_info,
    siblings = sibling_info.siblings,
    current_idx = sibling_info.current_idx,
    target_idx = sibling_info.target_idx,
  }
end

-- See get_validated_swap_context for safety rules.
---@param current_row integer: The row of the currently selected header
---@param target_row integer: The row of the target header to swap with
---@param direction "up" | "down": The direction of the swap
---@return boolean, integer|nil: success, new_cursor_position (if swap succeeded)
function M.swap_markdown_sections(current_row, target_row, direction)
  local ctx = get_validated_swap_context(current_row, target_row)
  if not ctx then return false, nil end

  local current = ctx.current
  local target = ctx.target

  -- Create an extmark at the current cursor position to track it during edits
  local ns_id = vim.api.nvim_create_namespace("treewalker_swap")
  local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, current_row - 1, 0, {})

  -- Perform the swap
  local ok, _ = ops.swap_buffer_ranges(
    current.start, current.finish,
    target.start, target.finish
  )

  if not ok then
    -- Clean up the extmark
    vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)
    return false, nil
  end

  -- Get the position where our cursor should be from the extmark
  local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, extmark_id, {})

  -- Clean up the extmark
  vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)

  -- Return the position or fallback based on direction
  if direction == "down" then
    -- For swap down, return new position of the original header
    return true, pos[1] + 1 -- Convert back to 1-indexed
  else
    -- For swap up, return target header position (maintain compatibility with tests)
    return true, target_row
  end
end

-- Swap down in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_down_markdown()
  local current_row = vim.fn.line(".")
  local info = heading.heading_info(current_row)

  if info.type ~= "heading" then return end

  local target_node, target_row = markdown_targets.get_next_same_level_heading(current_row)
  if not target_node or not target_row then
    return
  end

  local success, new_pos = M.swap_markdown_sections(current_row, target_row, "down")
  if not success then return end
  if new_pos then vim.fn.cursor(new_pos, 1) end
end

-- Swap up in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_up_markdown()
  local current_row = vim.fn.line(".")
  local info = heading.heading_info(current_row)

  if info.type ~= "heading" then return end

  local target_node, target_row = markdown_targets.get_prev_same_level_heading(current_row)
  if not target_node or not target_row then
    return
  end

  local success, new_pos = M.swap_markdown_sections(current_row, target_row, "up")
  if not success then return end
  if new_pos then vim.fn.cursor(new_pos, 1) end
end

return M
