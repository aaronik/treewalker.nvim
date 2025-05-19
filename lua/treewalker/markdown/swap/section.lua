local ops = require "treewalker.operations"
local validate = require "treewalker.markdown.validation"
local markdown_selectors = require "treewalker.markdown.selectors"
local heading = require "treewalker.markdown.heading"

local M = {}

-- See get_validated_swap_context for safety rules.
-- @param current_row integer: The row of the currently selected header
-- @param target_row integer: The row of the target header to swap with
-- @param direction "up" | "down": The direction of the swap
-- @return boolean, integer|nil: success, new_cursor_position (if swap succeeded)
function M.swap_markdown_sections(current_row, target_row, direction)
  local ctx = validate.get_validated_swap_context(current_row, target_row)
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
  if info.type == "heading" then
    local target_node, target_row = markdown_selectors.get_next_same_level_heading(current_row)
    if not target_node or not target_row then
      return
    end

    local success, new_pos = M.swap_markdown_sections(current_row, target_row, "down")
    if success then
      if new_pos then
        vim.fn.cursor(new_pos, 1)
      else
        vim.fn.cursor(target_row, 1)
      end
      return
    end
  end
end

-- Swap up in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_up_markdown()
  local current_row = vim.fn.line(".")
  local info = heading.heading_info(current_row)
  if info.type == "heading" then
    local target_node, target_row = markdown_selectors.get_prev_same_level_heading(current_row)
    if not target_node or not target_row then
      return
    end

    local success, new_pos = M.swap_markdown_sections(current_row, target_row, "up")
    if success then
      if new_pos then
        vim.fn.cursor(new_pos, 1)
      else
        vim.fn.cursor(target_row, 1)
      end
      return
    end
  end
end

return M
