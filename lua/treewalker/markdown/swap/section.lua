local ops = require "treewalker.operations"
local validate = require "treewalker.markdown.validation"
local swap_cursor_utils = require "treewalker.markdown.swap_cursor_utils"
local markdown_selectors = require "treewalker.markdown.selectors"
local markdown_line_utils = require "treewalker.markdown.line_utils"

local M = {}

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
  local ok, _ = ops.swap_buffer_ranges(
    current.start, current.finish,
    target.start, target.finish
  )
  if not ok then
    return false, nil
  end
  local new_pos = swap_cursor_utils.adjust_cursor_after_swap(current, target, direction)
  return true, new_pos
end

-- Swap down in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_down_markdown()
  local current_row = vim.fn.line(".")
  local info = markdown_line_utils.classify_line(current_row)
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
    else
      return
    end
  end
end

-- Swap up in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_up_markdown()
  local current_row = vim.fn.line(".")
  local info = markdown_line_utils.classify_line(current_row)
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
    else
      return
    end
  end
end

return M
