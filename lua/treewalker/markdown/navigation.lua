local selectors = require "treewalker.markdown.selectors"
local heading = require "treewalker.markdown.heading"
local nodes = require "treewalker.nodes"

local M = {}

----------------------------------------------------------------------
-- Core heading movement (up, down, in, out) for markdown navigation --
----------------------------------------------------------------------

function M.find_down(current_row)
  if heading.is_heading(current_row) then
    local target_node, target_row = selectors.get_next_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    else
      return nodes.get_at_row(current_row), current_row
    end
  else
    local target_node, target_row = selectors.get_nearest_next_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
  return nil, nil
end

function M.find_up(current_row)
  if not heading.is_heading(current_row) then
    local target_node, target_row = selectors.get_nearest_prev_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  else
    if current_row == 1 then
      return nil, nil
    end
    local target_node, target_row = selectors.get_prev_same_level_heading(current_row)
    if target_node and target_row then
      return target_node, target_row
    end
  end
  return nil, nil
end

function M.find_in(current_row)
  -- Move in: go to first child heading, or remain if none.
  if not heading.is_heading(current_row) then return nil, nil end
  local cur_level = heading.heading_level(current_row)
  local max_row = vim.api.nvim_buf_line_count(0)
  for row = current_row + 1, max_row do
    local info = heading.heading_info(row)
    if info.type == "heading" then
      if info.level == cur_level + 1 then
        return nodes.get_at_row(row), row
      elseif info.level <= cur_level then
        break
      end
    end
  end
  return nodes.get_at_row(current_row), current_row
end

function M.find_out(current_row)
  -- Move out: go to nearest parent heading above.
  if not heading.is_heading(current_row) then
    local cur = current_row
    while cur > 1 do
      cur = cur - 1
      local info = heading.heading_info(cur)
      if info.type == "heading" then
        return nodes.get_at_row(cur), cur
      end
    end
    return nil, nil
  end
  local cur_level = heading.heading_level(current_row)
  local cur = current_row
  while cur > 1 do
    cur = cur - 1
    local info = heading.heading_info(cur)
    if info.type == "heading" and info.level < cur_level then
      return nodes.get_at_row(cur), cur
    end
  end
  return nil, nil
end

return M
