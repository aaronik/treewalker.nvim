---
-- Utility for calculating new cursor positions after a swap of two ranges.
-- Used primarily by section_swap but potentially reusable in other contexts.
-- @param current  table: Section table for the originally selected header block
-- @param target   table: Section table for the swap target header block
-- @param direction string: "up"|"down" indicating swap direction
-- @return integer: The new cursor position (row)
local M = {}

function M.adjust_cursor_after_swap(current, target, direction)
  if direction == "down" then
    local current_length = current.finish - current.start
    local target_length = target.finish - target.start
    local length_diff = current_length - target_length
    return target.start - length_diff
  else
    return target.start
  end
end

return M
