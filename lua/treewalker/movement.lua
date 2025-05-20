local operations = require "treewalker.operations"
local targets = require "treewalker.targets"
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
  vim.cmd("normal! ^") -- TODO can somehow use nodes.get_at_row for this instead of this junk?
  local node = nodes.get_current()
  local target, row = targets.out(node)
  if not (target and row) then
    operations.jump(node, nodes.get_srow(node))
    return
  end
  add_jumplist_for_move('move_out')
  operations.jump(target, row)
  add_jumplist_for_move('move_out') -- for easy Ctrl-o/Ctrl-i navigation
end

---@return nil
function M.move_in()
  local target, row = targets.inn()
  if not target or not row then return end
  add_jumplist_for_move('move_in')
  operations.jump(target, row)
  add_jumplist_for_move('move_in')
end

---@return nil
function M.move_up()
  local node = nodes.get_current()
  local target, row = targets.up()
  if not target or not row then return end

  local is_neighbor = nodes.have_neighbor_srow(node, target)

  if not is_neighbor then
    add_jumplist_for_move('move_up')
  end

  operations.jump(target, row)
end

---@return nil
function M.move_down()
  local node = nodes.get_current()
  local target, row = targets.down()
  if not target or not row then return end

  local is_neighbor = nodes.have_neighbor_srow(node, target)

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end

  operations.jump(target, row)

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end
end

return M
