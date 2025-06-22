local nodes = require "treewalker.nodes"
local operations = require "treewalker.operations"
local targets = require "treewalker.targets"
local augment = require "treewalker.augment"
local strategies = require "treewalker.strategies"
local util = require "treewalker.util"
local markdown_swap = require "treewalker.markdown.swap.section"
local markdown_heading = require "treewalker.markdown.heading"

local M = {}

---@return boolean
local function is_on_target_node()
  local node = vim.treesitter.get_node()
  if not node then return false end

  -- Special case for markdown - use heading utility
  if util.is_markdown_file() then
    return markdown_heading.is_heading(vim.fn.line("."))
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
  }

  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  return not unsupported_filetypes[ft]
end

function M.swap_down()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if not is_on_target_node() then return end
  if util.is_markdown_file() then
    return markdown_swap.swap_down_markdown()
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
  if util.is_markdown_file() then
    return markdown_swap.swap_up_markdown()
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
  if util.is_markdown_file() then return end
  local current = nodes.get_current()
  current = strategies.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)

  local target = nodes.next_sib(current)

  if not target then
    M.reorder(current, "right") 
  end

  if not current or not target then return end

  -- set a mark to track where the target started, so we may later go there after the swap
  local ns_id = vim.api.nvim_create_namespace("treewalker#swap_right")
  local ext_id = vim.api.nvim_buf_set_extmark(
    0,
    ns_id,
    nodes.get_srow(target) - 1,
    nodes.get_scol(target) - 1,
    {}
  )

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
  if util.is_markdown_file() then return end
  local current = nodes.get_current()
  current = strategies.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)

  local target = nodes.prev_sib(current)

  if not target then
    M.reorder(current, "left")
  end

  if not current or not target then return end

  operations.swap_nodes(target, current)

  -- Place cursor
  vim.fn.cursor(
    nodes.get_srow(target),
    nodes.get_scol(target)
  )
end

---@param node TSNode
---@param fn function
function M.reorder(node, side)
  if not node or not side then return end
	operations.insert(node, side)
	node = nodes.get_current()
	operations.delete_at_end(node:parent(), side)
end

return M
