local anchor = require "treewalker.anchor"
local classify = require "treewalker.classify"
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

---@return TreewalkerAnchor | nil
local function current_vertical_anchor()
  local node = vim.treesitter.get_node()
  if not node or not classify.is_jump_target(node) then return nil end
  if vim.fn.line('.') - 1 ~= node:range() then return nil end
  return anchor.current()
end

function M.swap_down()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if util.is_markdown_file() then
    if not markdown_heading.is_heading(vim.fn.line(".")) then return end
    markdown_swap.swap_down_markdown()
    return
  end

  local current = current_vertical_anchor()
  if not current then return end

  local target = anchor.find_down(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  operations.swap_rows(current.attached_rows, target.attached_rows)

  -- Place cursor
  local node_length_diff = (current.end_row - current.row) - (target.end_row - target.row)
  vim.fn.cursor(target.row - node_length_diff, target.col)
end

function M.swap_up()
  vim.cmd("normal! ^")
  if not is_supported_ft() then return end
  if util.is_markdown_file() then
    if not markdown_heading.is_heading(vim.fn.line(".")) then return end
    markdown_swap.swap_up_markdown()
    return
  end

  local current = current_vertical_anchor()
  if not current then return end

  local target = anchor.find_up(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  -- Do the swap
  operations.swap_rows(target.attached_rows, current.attached_rows)

  -- Place cursor
  vim.fn.cursor(target.row + current.augment_length - target.augment_length, target.col)
end

function M.swap_right()
  if not is_supported_ft() then return end
  if util.is_markdown_file() then return end
  local current = anchor.current_lateral_node()
  local target = anchor.next_sibling(current)

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
  local new_current = vim.treesitter.get_node({
    pos = { ext[1], ext[2] - 1 },
    ignore_injections = false,
  })

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
  local current = anchor.current_lateral_node()
  local target = anchor.prev_sibling(current)

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
