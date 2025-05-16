local range_ops = require "treewalker.markdown.range_ops"
local validate = require "treewalker.markdown.validation"
local swap_cursor_utils = require "treewalker.markdown.swap_cursor_utils"

local M = {}

---
-- Public API: Swap two Markdown header sections (and their content)
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
  local ok, _ = range_ops.swap_buffer_ranges(
    current.start, current.finish,
    target.start, target.finish
  )
  if not ok then
    return false, nil
  end
  local new_pos = swap_cursor_utils.adjust_cursor_after_swap(current, target, direction)
  return true, new_pos
end

-- Returns the new cursor position after a markdown swap.
-- (Moved to swap_cursor_utils.lua)

return M
