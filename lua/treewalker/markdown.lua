local util = require "treewalker.util"
local lines= require "treewalker.lines"
local nodes= require "treewalker.nodes"
local M = {}

-- Helper function to determine markdown heading level
---@param row integer
---@return integer | nil, boolean | nil
function M.get_markdown_heading_level(row)
  if not row then return nil, nil end

  if not util.is_markdown_file() then return nil, nil end

  local line = lines.get_line(row)
  if not line then return nil, nil end

  -- Check if this is a heading line starting with #
  local level_match = line:match("^(#+)%s")
  if level_match then
    return #level_match, false -- Second param indicates if this is an underline
  end

  -- Check if this line is an underline (===== or -----) and consider it NOT a heading
  if line:match("^=+%s*$") or line:match("^-+%s*$") then
    return nil, true -- This is an underline, not a heading
  end

  -- Check if this is an h1 or h2 with underline style
  if row < vim.api.nvim_buf_line_count(0) then
    local next_line = lines.get_line(row + 1)
    if line and line:match("^%S") and next_line then
      if next_line:match("^=+%s*$") then
        return 1, false -- This is an H1 heading
      elseif next_line:match("^-+%s*$") then
        return 2, false -- This is an H2 heading
      end
    end
  end

  return nil, false -- Not a heading
end

-- For markdown heading navigation - get next heading at same level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Get heading level from current position
  local current_level, is_underline = M.get_markdown_heading_level(row)

  -- If we're on an underline, go back to the heading
  if is_underline and row > 1 then
    row = row - 1
    current_level = M.get_markdown_heading_level(row)
  end

  if not current_level then return nil, nil end

  local max_row = vim.api.nvim_buf_line_count(0)

  -- Search for next heading of same level
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(next_row)
    -- Skip underlines
    if is_under then goto continue end

    -- Found a heading of the same level
    if level and level == current_level then
      local node = nodes.get_at_row(next_row)
      return node, next_row
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown heading navigation - get previous heading at same level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Get heading level from current position
  local current_level, is_underline = M.get_markdown_heading_level(row)

  -- If we're on an underline, go back to the heading
  if is_underline and row > 1 then
    row = row - 1
    current_level = M.get_markdown_heading_level(row)
  end

  -- If not on a heading, find the nearest previous heading
  if not current_level then
    return M.get_nearest_prev_heading(row)
  end

  -- Search for previous heading of same level
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(prev_row)
    -- Skip underlines
    if is_under then goto continue end

    if level then
      -- For the "Moves up to same level node the same way it moves down" test
      -- We want to find a heading of the same level, no matter what level it is
      if level == current_level then
        local node = nodes.get_at_row(prev_row)
        return node, prev_row
      end
      -- Remove this check to fix the test case
      -- It was preventing finding H3 after encountering any higher level heading
      -- elseif level < current_level then
      --   -- Found a heading of higher level (smaller number), so stop searching
      --   -- We only want to find headings at the same level
      --   break
      -- end
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown - finds the nearest heading above the current row
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_prev_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Search for any previous heading
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(prev_row)
    -- Skip underlines
    if is_under then goto continue end

    if level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown - finds the nearest heading below the current row
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_next_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Search for any next heading
  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(next_row)
    -- Skip underlines
    if is_under then goto continue end

    if level then
      local node = nodes.get_at_row(next_row)
      return node, next_row
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown heading navigation - get inner heading (one level deeper)
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_inner_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Get heading level from current position
  local current_level, is_underline = M.get_markdown_heading_level(row)

  -- If we're on an underline, go back to the heading
  if is_underline and row > 1 then
    row = row - 1
    current_level = M.get_markdown_heading_level(row)
  end

  if not current_level then return nil, nil end

  local target_level = current_level + 1
  local max_row = vim.api.nvim_buf_line_count(0)

  -- Search for next heading one level deeper
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(next_row)
    -- Skip underlines
    if is_under then goto continue end

    if level then
      if level == target_level then
        local node = nodes.get_at_row(next_row)
        return node, next_row
      elseif level <= current_level then
        -- We found a heading of the same or higher level before finding
        -- a deeper heading, so stop searching
        return nil, nil
      end
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown heading navigation - get outer heading (one level higher)
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_outer_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  -- Get heading level from current position
  local current_level, is_underline = M.get_markdown_heading_level(row)

  -- If we're on an underline, go back to the heading
  if is_underline and row > 1 then
    row = row - 1
    current_level = M.get_markdown_heading_level(row)
  end

  if not current_level or current_level <= 1 then return nil, nil end

  local target_level = current_level - 1

  -- Search for previous heading one level higher
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level, is_under = M.get_markdown_heading_level(prev_row)
    -- Skip underlines
    if is_under then goto continue end

    if level and level == target_level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end

    ::continue::
  end

  return nil, nil
end

return M
