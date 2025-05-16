local nodes = require "treewalker.nodes"
local operations = require "treewalker.operations"
local targets = require "treewalker.targets"
local augment = require "treewalker.augment"
local strategies = require "treewalker.strategies"

local M = {}

---@return boolean
local function is_markdown_file()
  local ft = vim.bo.ft
  return ft == "markdown" or ft == "md"
end

---@return boolean
local function is_on_target_node()
  local node = vim.treesitter.get_node()
  if not node then return false end

  -- Special case for markdown - we need to check if we're on a heading
  if is_markdown_file() then
    local row = vim.fn.line(".")
    local level = strategies.get_markdown_heading_level(row)
    return level ~= nil
  end

  -- For other languages, use the standard Treesitter-based approach
  if not nodes.is_jump_target(node) then return false end
  if vim.fn.line('.') - 1 ~= node:range() then return false end
  return true
end

---@return boolean
local function is_supported_ft()
  local unsupported_filetypes = {
    ["text"] = true,
    ["txt"] = true,
    -- Markdown is now supported for header swapping
  }

  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  return not unsupported_filetypes[ft]
end

---@param row integer
---@return integer | nil, integer | nil, integer | nil
local function get_markdown_section_bounds(row)
  if not is_markdown_file() then return nil, nil, nil end
  -- Get the level of the current header
  local level = strategies.get_markdown_heading_level(row)
  if not level then return nil, nil, nil end
  local start_row = row
  local end_row = nil
  local max_row = vim.api.nvim_buf_line_count(0)
  -- Find the end of this section (next header of same or higher level)
  for next_row = row + 1, max_row do
    local next_level = strategies.get_markdown_heading_level(next_row)
    if next_level and next_level <= level then
      end_row = next_row - 1
      break
    end
  end
  -- If we didn't find an end, the section goes to the end of file
  if not end_row then
    end_row = max_row
  end
  return level, start_row, end_row
end

local function find_parent_header(row, level)
  for r = row - 1, 1, -1 do
    local l, is_underline = strategies.get_markdown_heading_level(r)
    if l and not is_underline and l < level then
      return r, l
    end
  end
  return nil, nil
end

local function get_parent_section_bounds(row, level)
  local parent_row, parent_level = find_parent_header(row, level)
  if parent_row and parent_level then
    return get_markdown_section_bounds(parent_row)
  end
  return nil, 1, vim.api.nvim_buf_line_count(0)
end

local function list_sibling_headers_of_level_in_bounds(level, parent_row, start_row, end_row)
  local result = {}
  for r = start_row, end_row do
    local l = strategies.get_markdown_heading_level(r)
    if l == level then
      local this_p, _ = find_parent_header(r, l)
      if this_p == parent_row then
        table.insert(result, r)
      end
    end
  end
  return result
end

---@param current_row integer
---@param target_row integer
---@param direction "up" | "down"
---@return boolean, integer|nil
local function swap_markdown_sections(current_row, target_row, direction)
  if not is_markdown_file() then return false, nil end
  -- Get info for current section
  local current_level, current_start, current_end = get_markdown_section_bounds(current_row)
  if not current_level then return false, nil end
  -- Get info for target section
  local target_level, target_start, target_end = get_markdown_section_bounds(target_row)
  if not target_level then return false, nil end
  -- Only swap sections of the same level
  if current_level ~= target_level then
    return false, nil
  end
  local current_parent_row = find_parent_header(current_row, current_level)
  local target_parent_row = find_parent_header(target_row, target_level)
  local _, current_parent_start, current_parent_end = get_parent_section_bounds(current_row, current_level)
  local _, target_parent_start, target_parent_end = get_parent_section_bounds(target_row, target_level)
  if current_parent_row ~= target_parent_row then
    return false, nil
  end
  if current_parent_start ~= target_parent_start or current_parent_end ~= target_parent_end then
    return false, nil
  end
  if current_parent_row ~= nil then
    if not (
          current_start >= current_parent_start and current_end <= current_parent_end and
          target_start >= current_parent_start and target_end <= current_parent_end
        ) then
      return false, nil
    end
  else
    local global_start, global_end = 1, vim.api.nvim_buf_line_count(0)
    if not (
          current_start >= global_start and current_end <= global_end and
          target_start >= global_start and target_end <= global_end
        ) then
      return false, nil
    end
  end
  local sibling_headers = list_sibling_headers_of_level_in_bounds(current_level, current_parent_row,
    current_parent_start + 1, current_parent_end)
  local current_idx, target_idx
  for i, v in ipairs(sibling_headers) do
    if v == current_row then current_idx = i end
    if v == target_row then target_idx = i end
  end
  if not current_idx or not target_idx then
    return false, nil
  end
  if math.abs(current_idx - target_idx) ~= 1 then
    return false, nil
  end
  if current_row < target_row then
    for row = current_row + 1, target_row - 1 do
      local lvl, is_underline = strategies.get_markdown_heading_level(row)
      if lvl and not is_underline and lvl <= current_level then
        return false, nil
      end
    end
  else
    for row = target_row + 1, current_row - 1 do
      local lvl, is_underline = strategies.get_markdown_heading_level(row)
      if lvl and not is_underline and lvl <= current_level then
        return false, nil
      end
    end
  end
  local current_section = vim.api.nvim_buf_get_lines(0, current_start - 1, current_end, false)
  local target_section = vim.api.nvim_buf_get_lines(0, target_start - 1, target_end, false)
  -- Safeguard against empty sections
  if #current_section == 0 or #target_section == 0 then
    return false, nil
  end
  -- Create copies to avoid reference issues
  local current_section_copy = vim.deepcopy(current_section)
  local target_section_copy = vim.deepcopy(target_section)
  if current_start > target_start then
    -- Current section is after target - replace current first, then target
    vim.api.nvim_buf_set_lines(0, current_start - 1, current_end, false, target_section_copy)
    vim.api.nvim_buf_set_lines(0, target_start - 1, target_end, false, current_section_copy)
  else
    -- Target section is after current - replace target first, then current
    vim.api.nvim_buf_set_lines(0, target_start - 1, target_end, false, current_section_copy)
    vim.api.nvim_buf_set_lines(0, current_start - 1, current_end, false, target_section_copy)
  end
  local new_pos
  if direction == "down" then
    local current_length = current_end - current_start
    local target_length = target_end - target_start
    local length_diff = current_length - target_length
    new_pos = target_start - length_diff
  else
    new_pos = target_start
  end
  return true, new_pos
end

function M.swap_down()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if not is_on_target_node() then return end
  -- Special handling for markdown files
  if is_markdown_file() then
    local current_row = vim.fn.line(".")
    -- Check if we're on a heading
    local level = strategies.get_markdown_heading_level(current_row)
    if level then
      -- Find the next heading at the same level
      local target_node, target_row = strategies.get_next_same_level_heading(current_row)
      -- If no target found, just return (don't proceed to default behavior)
      -- This is important for H1 headings where there might be only one
      if not target_node or not target_row then
        return
      end

      -- Swap the sections and get the new cursor position
      local success, new_pos = swap_markdown_sections(current_row, target_row, "down")
      if success then
        if new_pos then
          -- Move the cursor to where our header went (tracked by extmark)
          vim.fn.cursor(new_pos, 1)
        else
          -- Fallback position
          vim.fn.cursor(target_row, 1)
        end
        return
      else
        return
      end
      -- If we couldn't swap with next header of same level, try to default behavior
    end
  end

  local current = nodes.get_current()

  local target = targets.down()
  if not target then return end

  current = nodes.get_highest_coincident(current)

  local current_augments = augment.get_node_augments(current)
  local current_all = { current, unpack(current_augments) }
  local current_srow = nodes.get_srow(current)
  local current_erow = nodes.get_erow(current)
  local current_all_rows = nodes.whole_range(current_all)

  local target_augments = augment.get_node_augments(target)
  local target_all = { target, unpack(target_augments) }
  local target_srow = nodes.get_srow(target)
  local target_erow = nodes.get_erow(target)
  local target_scol = nodes.get_scol(target)
  local target_all_rows = nodes.whole_range(target_all)
  operations.swap_rows(current_all_rows, target_all_rows)

  -- Place cursor
  local node_length_diff = (current_erow - current_srow) - (target_erow - target_srow)
  local x = target_srow - node_length_diff
  local y = target_scol
  vim.fn.cursor(x, y)
end

function M.swap_up()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if not is_on_target_node() then return end
  -- Special handling for markdown files
  if is_markdown_file() then
    local current_row = vim.fn.line(".")

    -- Check if we're on a heading
    local level = strategies.get_markdown_heading_level(current_row)
    if level then
      -- Find the previous heading at the same level
      local target_node, target_row = strategies.get_prev_same_level_heading(current_row)
      -- If no target found, just return (don't proceed to default behavior)
      -- This is important for H1 headings where there might be only one
      if not target_node or not target_row then
        return
      end

      -- Swap the sections and get the new cursor position
      local success, new_pos = swap_markdown_sections(current_row, target_row, "up")
      if success then
        if new_pos then
          -- Move the cursor to where our header went (tracked by extmark)
          vim.fn.cursor(new_pos, 1)
        else
          -- Fallback position
          vim.fn.cursor(target_row, 1)
        end
        return
      else
        return
      end
    end
  end

  local current = nodes.get_current()
  local target = targets.up()
  if not target then return end

  current = nodes.get_highest_coincident(current)

  local current_augments = augment.get_node_augments(current)
  local current_all = { current, unpack(current_augments) }
  local current_srow = nodes.get_srow(current)
  local current_all_rows = nodes.whole_range(current_all)

  local target_srow = nodes.get_srow(target)
  local target_scol = nodes.get_scol(target)
  local target_augments = augment.get_node_augments(target)
  local target_all = { target, unpack(target_augments) }
  local target_all_rows = nodes.whole_range(target_all)

  local target_augment_rows = nodes.whole_range(target_augments)
  local target_augment_srow = target_augment_rows[1]
  local target_augment_length = #target_augments == 0 and 0 or (target_srow - target_augment_srow - 1)

  local current_augment_rows = nodes.whole_range(current_augments)
  local current_augment_srow = current_augment_rows[1]
  local current_augment_length = #current_augments == 0 and 0 or (current_srow - current_augment_srow - 1)

  -- Do the swap
  operations.swap_rows(target_all_rows, current_all_rows)

  -- Place cursor
  local x = target_srow + current_augment_length - target_augment_length
  local y = target_scol
  vim.fn.cursor(x, y)
end

function M.swap_right()
  if not is_supported_ft() then return end
  -- Left/right swapping is disabled for markdown files
  if is_markdown_file() then return end
  -- Iteratively more desirable
  local current = nodes.get_current()
  current = strategies.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)
  local target = nodes.next_sib(current)
  if not current or not target then return end
  -- set a mark to track where the target started, so we may later go there after the swap
  local ns_id = vim.api.nvim_create_namespace("treewalker#swap_right")
  local ext_id = vim.api.nvim_buf_set_extmark(0, ns_id, nodes.get_srow(target) - 1, nodes.get_scol(target) - 1, {})
  operations.swap_nodes(current, target)
  local ext = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, ext_id, {})
  local new_current = nodes.get_at_rowcol(ext[1] + 1, ext[2] - 1)
  if not new_current then return end
  vim.fn.cursor(
    nodes.get_srow(new_current),
    nodes.get_scol(new_current)
  )
  -- cleanup
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

function M.swap_left()
  if not is_supported_ft() then return end
  -- Left/right swapping is disabled for markdown files
  if is_markdown_file() then return end
  -- Iteratively more desirable
  local current = nodes.get_current()
  current = strategies.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)
  local target = nodes.prev_sib(current)
  if not current or not target then return end
  operations.swap_nodes(target, current)
  -- Place cursor
  vim.fn.cursor(
    nodes.get_srow(target),
    nodes.get_scol(target)
  )
end

return M
