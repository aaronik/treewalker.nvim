local markdown_anchor = require "treewalker.markdown.anchor"
local ops = require "treewalker.operations"

local M = {}

-- Swap two markdown section anchors.
---@param current MarkdownAnchor
---@param target MarkdownAnchor
---@param direction "up" | "down"
---@return boolean, integer|nil
function M.swap_markdown_sections(current, target, direction)
  if current.level ~= target.level then return false, nil end
  if current.parent_row ~= target.parent_row then return false, nil end

  -- Create an extmark at the current cursor position to track it during edits
  local ns_id = vim.api.nvim_create_namespace("treewalker_swap")
  local extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, current.heading_row - 1, 0, {})

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

  if direction == "down" then
    return true, pos[1] + 1
  end

  return true, target.heading_row
end

-- Swap down in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_down_markdown()
  local current = markdown_anchor.current_heading(vim.fn.line('.'))
  if not current then return end

  local target = markdown_anchor.next_swappable_sibling(current)
  if not target then return end

  local success, new_pos = M.swap_markdown_sections(current, target, "down")
  if not success then return end
  if new_pos then vim.fn.cursor(new_pos, 1) end
end

-- Swap up in markdown file: handling finding neighbor heading and calling swap_markdown_sections
function M.swap_up_markdown()
  local current = markdown_anchor.current_heading(vim.fn.line('.'))
  if not current then return end

  local target = markdown_anchor.prev_swappable_sibling(current)
  if not target then return end

  local success, new_pos = M.swap_markdown_sections(current, target, "up")
  if not success then return end
  if new_pos then vim.fn.cursor(new_pos, 1) end
end

return M
