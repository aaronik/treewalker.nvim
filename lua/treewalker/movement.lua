local operations = require "treewalker.operations"
local backend = require "treewalker.backend"
local confinement = require "treewalker.confinement"
local nodes = require "treewalker.nodes"

local M = {}

local function should_add_jumplist(command)
  local opts = require('treewalker').opts
  local jumplist = opts.jumplist

  if jumplist == false then return false end

  -- Only 'move_out' (left) jumps get jumplist in 'left' mode
  if jumplist == 'left' then
    return command == 'move_out'
  end

  return true
end

local function add_jumplist_for_move(command)
  if should_add_jumplist(command) then
    vim.cmd("normal! m'")
  end
end

---@return nil
function M.move_out()
  -- Add to jumplist at original cursor position before normalizing
  add_jumplist_for_move('move_out')

  local current_node = nodes.get_highest_node_at_current_row()
  local target, row = backend.get_target("find_out", current_node, nodes.get_srow(current_node))
  if not (target and row) then
    operations.jump(current_node, nodes.get_srow(current_node))
    return
  end
  operations.jump(target, row)
  add_jumplist_for_move('move_out') -- for easy Ctrl-o/Ctrl-i navigation
end

---@return nil
function M.move_in()
  local current_node, current_row = nodes.get_highest_node_at_current_row()
  local target, row = backend.get_target("find_in", current_node, current_row)
  if not target or not row then return end
  add_jumplist_for_move('move_in')
  operations.jump(target, row)
  add_jumplist_for_move('move_in')
end

---@return nil
function M.move_up()
  local current_node, current_row = nodes.get_highest_node_at_current_row()
  local target, row = backend.get_target("find_up", current_node, current_row)
  if not target or not row then return end

  if confinement.should_confine(current_node, target) then
    return
  end

  local is_neighbor = nodes.have_neighbor_srow(current_node, target)

  if not is_neighbor then
    add_jumplist_for_move('move_up')
  end

  operations.jump(target, row)
end

---@return nil
function M.move_down()
  local current_node, current_row = nodes.get_highest_node_at_current_row()
  local target, row = backend.get_target("find_down", current_node, current_row)
  if not target or not row then return end

  if confinement.should_confine(current_node, target) then
    return
  end

  local is_neighbor = nodes.have_neighbor_srow(current_node, target)

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end

  operations.jump(target, row)

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end
end

return M
