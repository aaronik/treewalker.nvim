local nodes = require "treewalker.nodes"
local operations = require "treewalker.operations"
local targets = require "treewalker.targets"
local augment = require "treewalker.augment"

local M = {}

---@return boolean
local function is_on_target_node()
  local node = vim.treesitter.get_node()
  if not node then return false end
  if not nodes.is_jump_target(node) then return false end
  if vim.fn.line('.') - 1 ~= node:range() then return false end
  return true
end

---@return boolean
local function is_supported_ft()
  local unsupported_filetypes = {
    ["text"] = true,
    ["markdown"] = true,
  }

  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  return not unsupported_filetypes[ft]
end

function M.swap_down()
  if not is_on_target_node() then return end
  if not is_supported_ft() then return end

  local target, row, line = targets.down()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  local current = nodes.get_row_current()
  local current_range = nodes.range(current)
  local current_augments = augment.get_node_augments(current)
  local current_all = { current, unpack(current_augments) }
  local current_all_rows = nodes.whole_range(current_all)

  local target_range = nodes.range(target)
  local target_augments = augment.get_node_augments(target)
  local target_all = { target, unpack(target_augments) }
  local target_all_rows = nodes.whole_range(target_all)

  operations.swap_rows(current_all_rows, target_all_rows)

  -- Place cursor
  local node_length_diff = ((current_range[3] - current_range[1]) + 1) - ((target_range[3] - target_range[1]) + 1)
  local x = target_range[1] - node_length_diff + 1
  local y = target_range[2] + 1
  vim.fn.cursor(x, y)
end

function M.swap_up()
  if not is_on_target_node() then return end
  if not is_supported_ft() then return end

  local target, row, line = targets.up()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  local current = nodes.get_row_current()
  local current_augments = augment.get_node_augments(current)
  local current_all = { current, unpack(current_augments) }
  local current_all_rows = nodes.whole_range(current_all)

  local target_range = nodes.range(target)
  local target_augments = augment.get_node_augments(target)
  local target_all = { target, unpack(target_augments) }
  local target_all_rows = nodes.whole_range(target_all)

  operations.swap_rows(target_all_rows, current_all_rows)

  -- Place cursor
  local target_augment_rows = nodes.whole_range(target_augments)
  local target_augment_length = #target_augments > 0 and (target_augment_rows[2] + 1 - target_augment_rows[1]) or 0
  local current_augment_rows = nodes.whole_range(current_augments)
  local current_augment_length = #current_augments > 0 and (current_augment_rows[2] + 1 - current_augment_rows[1]) or 0
  local x = target_range[1] + 1 + current_augment_length - target_augment_length
  local y = target_range[2] + 1
  vim.fn.cursor(x, y)
end

-- TODO oh snap should we just straight up disallow this op if we're on a jump target? That'd prevent the ability to do a lateral swap on nodes that should be vertically swapped. Oh nah that won't work for multiline argument lists
function M.swap_right()
  if not is_supported_ft() then return end

  local current = nodes.get_current()
  if not current then return end
  local next = current:next_named_sibling()
  if not next then return end

  local current_text = nodes.get_text(current)
  local next_text = nodes.get_text(next)

  operations.swap_nodes(current, next)

  -- Place cursor
  local on_same_row = nodes.get_row(current) == nodes.get_row(next)
  if on_same_row then
    vim.fn.cursor(
      nodes.get_row(current),
      nodes.get_col(current) + #next_text[1] + 2
    )
  else
    vim.fn.cursor(
      nodes.get_row(next) - #current_text + #next_text,
      nodes.get_col(next)
    )
  end
end

function M.swap_left()
  if not is_supported_ft() then return end

  local current = nodes.get_current()
  if not current then return end
  local prev = current:prev_named_sibling()
  if not prev then return end

  operations.swap_nodes(prev, current)

  -- Place cursor
  vim.fn.cursor(
    nodes.get_row(prev),
    nodes.get_col(prev)
  )
end

return M
