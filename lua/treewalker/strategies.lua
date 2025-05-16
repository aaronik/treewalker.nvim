-- All strategies follow a similar pattern of taking the information they need,
-- and also any previous return values from other strategies. This allows for
-- easy chaining, so instead of the old, we can use the new:
-- Old:
--
-- local candidate, candidate_row =
--     strategies.get_prev_if_on_empty_line(current_row)
--
-- if candidate and candidate_row then
--   return candidate, candidate_row
-- end
--
-- candidate, candidate_row =
--   strategies.get_neighbor_at_same_col("up", current_row, current_col)
--
-- if candidate and candidate_row then
--   return candidate, candidate_row
-- end
--
--
-- New:
--
-- local candidate, candidate_row =
--    local candidate, row
--    candidate, row = strategies.get_neighbor_at_same_col("up", current_row, current_col, nil, nil)
--    candidate, row = strategies.get_prev_if_on_empty_line(current_row, candidate, row)
--    return candidate, row
--
-- Notice how the order is switched, so least desirable candidates come first,
-- and most desirable last.
--
-- Also note this is only for multiple return strategies, all strategies that return only
-- a single node won't use this technique, as the following works better, preserving all types:
-- node = strategies.whatever(node) or node

local lines = require('treewalker.lines')
local nodes = require('treewalker.nodes')

local M = {}

-- Gets the next target in the up/down directions
---@param dir "up" | "down"
---@param srow integer
---@param scol integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return  TSNode | nil, integer | nil
function M.get_neighbor_at_same_col(dir, srow, scol, prev_candidate, prev_row)
  local candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(srow, dir)

  while candidate and candidate_row and candidate_line do
    local candidate_col = lines.get_start_col(candidate_line)
    local strow = candidate:range()
    if
        nodes.is_jump_target(candidate) -- only node types we consider jump targets
        and candidate_line ~= ""        -- no empty lines
        and candidate_col == scol       -- stay at current indent level
        and candidate_row == strow + 1  -- top of block; no end's or else's etc.
    then
      break                             -- use most recent assignment below
    else
      candidate, candidate_row, candidate_line = nodes.get_from_neighboring_line(candidate_row, dir)
    end
  end

  if candidate and candidate_row then
    return candidate, candidate_row
  else
    return prev_candidate, prev_row
  end
end

-- Go down until there is a valid jump target to the right
---@param srow integer
---@param scol integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_down_and_in(srow, scol, prev_candidate, prev_row)
  local last_row = vim.api.nvim_buf_line_count(0)

  -- Can't go down if we're at the bottom
  if last_row == srow then return prev_candidate, prev_row end

  for candidate_row = srow + 1, last_row, 1 do
    local candidate_line = lines.get_line(candidate_row)
    if not candidate_line then goto continue end
    local candidate_col = lines.get_start_col(candidate_line)
    local candidate = nodes.get_at_row(candidate_row)
    local is_empty = candidate_line == ""

    if candidate_col == scol or not candidate then
      goto continue
    elseif candidate_col > scol and nodes.is_jump_target(candidate) then
      return candidate, candidate_row
    elseif candidate_col < scol and not is_empty then
      break
    end

    ::continue:: -- gross
  end

  return prev_candidate, prev_row
end

-- Special case for when starting on empty line. In that case, find the next
-- line with stuff on it, and go to that.
---@param srow integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_next_if_on_empty_line(srow, prev_candidate, prev_row)
  local start_line = lines.get_line(srow)
  if start_line ~= "" then return prev_candidate, prev_row end

  ---@type string | nil
  local current_line = start_line
  local max_row = vim.api.nvim_buf_line_count(0)
  local current_row = srow
  local current_node = nodes.get_at_row(current_row)

  while
    true
    and current_line == ""
    or current_node and not nodes.is_jump_target(current_node)
    and current_row <= max_row
  do
    current_row = current_row + 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row > max_row then return prev_candidate, prev_row end

  if current_node and current_row then
    return current_node, current_row
  else
    return prev_candidate, prev_row
  end
end

-- Special case for when starting on empty line. In that case, find the prev
-- line with stuff on it, and go to that.
---@param srow integer
---@param prev_candidate TSNode | nil
---@param prev_row integer | nil
---@return TSNode | nil, integer | nil
function M.get_prev_if_on_empty_line(srow, prev_candidate, prev_row)
  local start_line = lines.get_line(srow)
  if start_line ~= "" then return prev_candidate, prev_row end

  ---@type string | nil
  local current_line = start_line
  local current_row = srow
  local current_node = nodes.get_at_row(current_row)

  while
    true
    and current_line == ""
    or current_node and not nodes.is_jump_target(current_node)
    and current_row >= 0
  do
    current_row = current_row - 1
    current_line = lines.get_line(current_row)
    current_node = nodes.get_at_row(current_row)
  end

  if current_row < 0 then return prev_candidate, prev_row end

  if current_node and current_row then
    return current_node, current_row
  else
    return prev_candidate, prev_row
  end
end

---Get the nearest ancestral node _which has different coordinates than the passed in node_
---@param node TSNode
---@return TSNode | nil
function M.get_first_ancestor_with_diff_scol(node)
  local iter_ancestor = node:parent()
  while iter_ancestor do
    if
        true
        and nodes.is_jump_target(iter_ancestor)
        and not nodes.have_same_scol(node, iter_ancestor)
    then
      return iter_ancestor
    end

    iter_ancestor = iter_ancestor:parent()
  end
end

-- Use this to get the whole string from inside of a string
-- returns nils if the passed in node is not a string node
---@param node TSNode
---@return TSNode | nil
function M.get_highest_string_node(node)
  ---@type TSNode | nil
  local highest = nil
  ---@type TSNode | nil
  local iter = node

  while iter do
    if string.match(iter:type(), "string") then
      highest = iter
    end
    iter = iter:parent()
  end

  return highest
end

-- Helper function to determine markdown heading level
---@param row integer
---@return integer | nil
function M.get_markdown_heading_level(row)
  if not row then return nil end

  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil end

  local line = lines.get_line(row)
  if not line then return nil end

  -- Check if this is a heading line starting with #
  local level_match = line:match("^(#+)%s")
  if level_match then
    return #level_match
  end

  -- Check if this is an h1 with ======= underline
  if row == 1 and line:match("^%S") then
    local next_line = lines.get_line(row + 1)
    if next_line and next_line:match("^=+%s*$") then
      return 1
    end
  end

  -- Check for other underlined headings (= for h1, - for h2)
  if row < vim.api.nvim_buf_line_count(0) and line:match("^%S") then
    local next_line = lines.get_line(row + 1)
    if not next_line then
      return nil
    end

    if next_line:match("^=+%s*$") then
      return 1
    elseif next_line:match("^-+%s*$") then
      return 2
    end
  end

  -- We don't consider the underline itself as a heading for navigation purposes
  -- This allows navigation to work correctly between actual headings
  -- But the underline identification is still used in other functions

  return nil
end

-- For markdown heading navigation - get next heading at same level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_same_level_heading(row)
  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil, nil end

  -- Get heading level from current position
  local current_level = M.get_markdown_heading_level(row)
  if not current_level then return nil, nil end

  local max_row = vim.api.nvim_buf_line_count(0)

  -- Search for next heading of same level
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end

    local level = M.get_markdown_heading_level(next_row)
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
  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil, nil end

  -- Get heading level from current position
  local current_level = M.get_markdown_heading_level(row)

  -- If not on a heading, find the nearest previous heading
  if not current_level then
    return M.get_nearest_prev_heading(row)
  end

  -- Debug logging to help diagnose test issues
  -- print(string.format("Looking for previous heading at level %d from row %d", current_level, row))

  -- Search for previous heading of same level
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level = M.get_markdown_heading_level(prev_row)
    if level then
      -- Debug logging to help diagnose test issues
      -- print(string.format("Found heading at level %d at row %d", level, prev_row))

      if level == current_level then
        local node = nodes.get_at_row(prev_row)
        return node, prev_row
      elseif level < current_level then
        -- Found a heading of higher level (smaller number), so stop searching
        -- We only want to find headings at the same level
        break
      end
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown - finds the nearest heading above the current row
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_prev_heading(row)
  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil, nil end

  -- Search for any previous heading
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level = M.get_markdown_heading_level(prev_row)
    if level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end

    ::continue::
  end

  return nil, nil
end

-- For markdown heading navigation - get inner heading (one level deeper)
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_inner_heading(row)
  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil, nil end

  -- Get heading level from current position
  local current_level = M.get_markdown_heading_level(row)
  if not current_level then return nil, nil end

  local target_level = current_level + 1
  local max_row = vim.api.nvim_buf_line_count(0)

  -- Search for next heading one level deeper
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end

    local level = M.get_markdown_heading_level(next_row)
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
  local ft = vim.bo.ft
  -- Check for both "markdown" and "md" as valid filetypes
  if ft ~= "markdown" and ft ~= "md" then return nil, nil end

  -- Get heading level from current position
  local current_level = M.get_markdown_heading_level(row)
  if not current_level or current_level <= 1 then return nil, nil end

  local target_level = current_level - 1

  -- Search for previous heading one level higher
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end

    local level = M.get_markdown_heading_level(prev_row)
    if level and level == target_level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end

    ::continue::
  end

  return nil, nil
end

return M
