local lines = require('treewalker.lines')
local nodes = require('treewalker.nodes')
local util = require('treewalker.util')

local M = {}

-- Markdown heading level cache (local, clear each load)
local _md_heading_level_cache = {}

local function get_markdown_heading_level_cached(row)
  if _md_heading_level_cache[row] ~= nil then
    return _md_heading_level_cache[row][1], _md_heading_level_cache[row][2]
  end
  local level, is_underline = M.get_markdown_heading_level_uncached(row)
  _md_heading_level_cache[row] = {level, is_underline}
  return level, is_underline
end

-- Now public, in util: util.normalize_markdown_header_row(row)

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

-- Helper function to determine markdown heading level (real, uncached)
---@param row integer
---@return integer | nil, boolean | nil
function M.get_markdown_heading_level_uncached(row)
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

-- The rest is search/loop logic: swap all uses of .get_markdown_heading_level

M.get_markdown_heading_level = get_markdown_heading_level_cached

function M.get_next_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  local normalized_row, current_level = util.normalize_markdown_header_row(row)
  if not current_level then return nil, nil end

  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = normalized_row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(next_row)
    if is_under then goto continue end
    if level and level == current_level then
      local node = nodes.get_at_row(next_row)
      return node, next_row
    end
    ::continue::
  end
  return nil, nil
end

function M.get_prev_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  local normalized_row, current_level = util.normalize_markdown_header_row(row)
  if not current_level then
    return M.get_nearest_prev_heading(row)
  end
  for prev_row = normalized_row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(prev_row)
    if is_under then goto continue end
    if level and level == current_level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end
    ::continue::
  end
  return nil, nil
end

function M.get_nearest_prev_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  for prev_row = row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(prev_row)
    if is_under then goto continue end
    if level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end
    ::continue::
  end
  return nil, nil
end

function M.get_nearest_next_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(next_row)
    if is_under then goto continue end
    if level then
      local node = nodes.get_at_row(next_row)
      return node, next_row
    end
    ::continue::
  end
  return nil, nil
end

function M.get_next_inner_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  local normalized_row, current_level = util.normalize_markdown_header_row(row)
  if not current_level then return nil, nil end
  local target_level = current_level + 1
  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = normalized_row + 1, max_row do
    local line = lines.get_line(next_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(next_row)
    if is_under then goto continue end
    if level then
      if level == target_level then
        local node = nodes.get_at_row(next_row)
        return node, next_row
      elseif level <= current_level then
        return nil, nil
      end
    end
    ::continue::
  end
  return nil, nil
end

function M.get_prev_outer_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  local normalized_row, current_level = util.normalize_markdown_header_row(row)
  if not current_level or current_level <= 1 then return nil, nil end
  local target_level = current_level - 1
  for prev_row = normalized_row - 1, 1, -1 do
    local line = lines.get_line(prev_row)
    if not line then goto continue end
    local level, is_under = get_markdown_heading_level_cached(prev_row)
    if is_under then goto continue end
    if level and level == target_level then
      local node = nodes.get_at_row(prev_row)
      return node, prev_row
    end
    ::continue::
  end
  return nil, nil
end

-- =====================
-- Markdown Movement Logic Refactor
-- =====================
M.markdown_targets = {}

function M.markdown_targets.up(row)
  local normalized_row, level = util.normalize_markdown_header_row(row)
  local _, _unused = M.get_markdown_heading_level(normalized_row)
  if not level then
    return M.get_nearest_prev_heading(row)
  else
    if normalized_row == 1 then return nil, nil end
    return M.get_prev_same_level_heading(normalized_row)
  end
end

function M.markdown_targets.down(row)
  -- Normalize to ensure row refers to header text (not underline)
  local orig_row = row
  local normalized_row, level = util.normalize_markdown_header_row(row)
  local _, is_underline = M.get_markdown_heading_level(orig_row)
  -- If start on underline (e.g. line 2 after H1 with `===`), skip to actual next heading
  if is_underline then
    -- Find next actual header after the underline
    local max_row = vim.api.nvim_buf_line_count(0)
    for r = orig_row + 1, max_row do
      local l, under = M.get_markdown_heading_level(r)
      if l and not under then
        return nodes.get_at_row(r), r
      end
    end
    return nodes.get_at_row(orig_row), orig_row
  end

  -- The rest: as before after normalization
  if normalized_row == 1 and level == 1 then
    local next_row = normalized_row + 1
    local _, is_next_underline = M.get_markdown_heading_level(next_row)
    if is_next_underline then
      return nodes.get_at_row(next_row), next_row
    end
  end
  if level then
    local target_node, target_row = M.get_next_same_level_heading(normalized_row)
    if target_node and target_row then
      return target_node, target_row
    else
      return nodes.get_at_row(normalized_row), normalized_row
    end
  else
    return M.get_nearest_next_heading(row)
  end
end

function M.markdown_targets.out(row)
  local normalized_row, level = util.normalize_markdown_header_row(row)
  local _, _unused = M.get_markdown_heading_level(normalized_row)
  if not level then
    return M.get_nearest_prev_heading(row)
  elseif normalized_row == 1 then
    return nil, nil
  else
    local target_node, target_row = M.get_prev_outer_heading(normalized_row)
    if target_node and target_row then
      return target_node, target_row
    elseif level > 1 then
      for i = 1, normalized_row - 1 do
        local found_level = select(1, M.get_markdown_heading_level(i))
        if found_level == 1 then
          return nodes.get_at_row(i), i
        end
      end
    end
  end
  return nil, nil
end

function M.markdown_targets.inn(row)
  local normalized_row, level = util.normalize_markdown_header_row(row)
  local _, _unused = M.get_markdown_heading_level(normalized_row)
  if level then
    local target_node, target_row = M.get_next_inner_heading(normalized_row)
    if target_node and target_row then
      return target_node, target_row
    else
      return nodes.get_at_row(normalized_row), normalized_row
    end
  else
    return nodes.get_at_row(normalized_row), normalized_row
  end
end

-- Unified logic for markdown direction targets
-- Accepts a node (preferred) or nil (uses cursor as fallback)
function M.markdown_direction_target(direction, node)
  local dir_map = {
    out = M.markdown_targets.out,
    inn = M.markdown_targets.inn,
    up = M.markdown_targets.up,
    down = M.markdown_targets.down,
  }
  local fn = dir_map[direction]
  if not fn then
    error("Unknown markdown direction: " .. tostring(direction))
  end
  -- Use new util to extract row from node or fallback to cursor
  local row = util.resolve_row_col(node)
  -- row will be (row, col), but we want just row (1st ret)
  if type(row) == "table" then
    row = row[1]
  end
  return fn(row)
end

return M
