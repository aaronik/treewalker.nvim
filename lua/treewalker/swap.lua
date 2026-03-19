local anchor = require "treewalker.anchor"
local nodes = require "treewalker.nodes"
local operations = require "treewalker.operations"
local markdown_heading = require "treewalker.markdown.heading"
local markdown_swap = require "treewalker.markdown.swap.section"
local confinement = require "treewalker.confinement"
local util = require "treewalker.util"

local M = {}

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
  if util.is_markdown_file() then
    if not markdown_heading.is_heading(vim.fn.line(".")) then return end
    markdown_swap.swap_down_markdown()
    return
  end

  local current = anchor.current_swap()
  if not current then return end

  local target = anchor.find_down(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  operations.swap_rows(current.attached_rows, target.attached_rows)

  -- Place cursor
  local node_length_diff = (current.end_row - current.row) - (target.end_row - target.row)
  local x = target.row - node_length_diff
  local y = target.col
  vim.fn.cursor(x, y)
end

function M.swap_up()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if util.is_markdown_file() then
    if not markdown_heading.is_heading(vim.fn.line(".")) then return end
    markdown_swap.swap_up_markdown()
    return
  end

  local current = anchor.current_swap()
  if not current then return end

  local target = anchor.find_up(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  -- Do the swap
  operations.swap_rows(target.attached_rows, current.attached_rows)

  -- Place cursor
  local x = target.row + current.augment_length - target.augment_length
  local y = target.col
  vim.fn.cursor(x, y)
end

function M.swap_right()
  if not is_supported_ft() then return end
  if util.is_markdown_file() then return end
  local current = nodes.get_current()
  current = anchor.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)

  local target = nodes.next_sib(current)

  if not current or not target then return end

  if confinement.should_confine(current, target) then
    return
  end

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
  current = anchor.get_highest_string_node(current) or current
  current = nodes.get_highest_coincident(current)

  local target = nodes.prev_sib(current)

  if not current or not target then return end

  if confinement.should_confine(current, target) then
    return
  end

  operations.swap_nodes(target, current)

  -- Place cursor
  vim.fn.cursor(
    nodes.get_srow(target),
    nodes.get_scol(target)
  )
end

return M
