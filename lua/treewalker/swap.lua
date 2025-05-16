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

---@param current_row integer
---@param target_row integer
---@return boolean
local function swap_markdown_sections(current_row, target_row)
  if not is_markdown_file() then return false end
  -- Get info for current section
  local current_level, current_start, current_end = get_markdown_section_bounds(current_row)
  if not current_level then return false end
  -- Get info for target section
  local target_level, target_start, target_end = get_markdown_section_bounds(target_row)
  if not target_level then return false end
  -- Only swap sections of the same level
  -- Debug output (uncomment for debugging)
  -- print(string.format("current_level=%d, target_level=%d", current_level, target_level))
  if current_level ~= target_level then
    -- print("Levels don't match, aborting swap")
    return false
  end
  -- Debug output can be uncommented when needed
  -- print(string.format("Swapping sections: current [%d-%d], target [%d-%d]",
  --   current_start, current_end, target_start, target_end))
  -- Get the text of both sections
  local current_section = vim.api.nvim_buf_get_lines(0, current_start - 1, current_end, false)
  local target_section = vim.api.nvim_buf_get_lines(0, target_start - 1, target_end, false)
  -- Safeguard against empty sections
  if #current_section == 0 or #target_section == 0 then
    -- print("Warning: Empty section detected - aborting swap")
    return false
  end
  -- Create copies to avoid reference issues
  local current_section_copy = vim.deepcopy(current_section)
  local target_section_copy = vim.deepcopy(target_section)
  -- Store original content for debugging (uncomment when needed)
  -- local original_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Swap the sections
  -- We need to work backwards (higher line numbers first) to avoid position shifting
  if current_start > target_start then
    -- Current section is after target - replace current first, then target
    vim.api.nvim_buf_set_lines(0, current_start - 1, current_end, false, target_section_copy)
    vim.api.nvim_buf_set_lines(0, target_start - 1, target_end, false, current_section_copy)
  else
    -- Target section is after current - replace target first, then current
    vim.api.nvim_buf_set_lines(0, target_start - 1, target_end, false, current_section_copy)
    vim.api.nvim_buf_set_lines(0, current_start - 1, current_end, false, target_section_copy)
  end
  -- Print debug info (uncomment when needed)
  -- local new_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- print(string.format("Swap complete: original content length %d, new content length %d",
  --   #original_content, #new_content))
  return true
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
      if target_node and target_row then
        -- Swap the sections
        if swap_markdown_sections(current_row, target_row) then
          -- Position cursor at the target position
          vim.fn.cursor(target_row, 1)
          return
        end
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

  -- Debug output (uncomment when needed)
  -- print("current_augments, target_augments:", vim.inspect(current_augments), vim.inspect(target_augments))

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
      if target_node and target_row then
        -- Swap the sections
        if swap_markdown_sections(current_row, target_row) then
          -- Position cursor at the target position
          vim.fn.cursor(target_row, 1)
          return
        end
      end
      -- If we couldn't swap with previous header of same level, try default behavior
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

