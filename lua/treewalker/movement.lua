local operations = require "treewalker.operations"
local targets = require "treewalker.targets"
local nodes = require "treewalker.nodes"

local M = {}

---@return nil
function M.move_out()
  vim.cmd("normal! ^")
  local node = nodes.get_current()
  local target, row = targets.get_direction_target('out', node)
  if not (target and row) then
    operations.jump(node, nodes.get_srow(node))
    return
  end
  vim.cmd("normal! m'")
  operations.jump(target, row)
  vim.cmd("normal! m'")
end

---@return nil
function M.move_in()
  local node = nodes.get_current()
  local target, row = targets.get_direction_target('inn', node)
  if not target or not row then return end
  vim.cmd("normal! m'")
  operations.jump(target, row)
  vim.cmd("normal! m'")
end

---@return nil
function M.move_up()
  local node = nodes.get_current()
  local target, row = targets.get_direction_target('up', node)
  if not target or not row then return end

  local is_neighbor = nodes.have_neighbor_srow(node, target)
  if not is_neighbor then
    vim.cmd("normal! m'")
  end

  operations.jump(target, row)
end

---@return nil
function M.move_down()
  local node = nodes.get_current()
  if not node then
    return
  end

  local target, row = targets.get_direction_target('down', node)
  if not target or not row then return end

  local is_neighbor = nodes.have_neighbor_srow(node, target)
  if not is_neighbor then
    vim.cmd("normal! m'")
  end

  operations.jump(target, row)

  if not is_neighbor then
    vim.cmd("normal! m'")
  end
end

return M
