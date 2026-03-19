local anchor = require "treewalker.anchor"
local operations = require "treewalker.operations"
local confinement = require "treewalker.confinement"
local markdown_targets = require "treewalker.markdown.targets"
local util = require "treewalker.util"

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

  if util.is_markdown_file() then
    local current = anchor.current()
    local target, row = markdown_targets.find_out(current.node, current.row)
    if not (target and row) then
      operations.jump(current.node, current.row)
      return
    end

    operations.jump(target, row)
    add_jumplist_for_move('move_out') -- for easy Ctrl-o/Ctrl-i navigation
    return
  end

  local current = anchor.current()
  local target = anchor.find_out(current)
  if not target then
    operations.jump(current.node, current.row)
    return
  end

  operations.jump(target.node, target.row)
  add_jumplist_for_move('move_out') -- for easy Ctrl-o/Ctrl-i navigation
end

---@return nil
function M.move_in()
  if util.is_markdown_file() then
    local current = anchor.current()
    local target, row = markdown_targets.find_in(current.node, current.row)
    if not target or not row then return end
    add_jumplist_for_move('move_in')
    operations.jump(target, row)
    add_jumplist_for_move('move_in')
    return
  end

  local current = anchor.current()
  local target = anchor.find_in(current)
  if not target then return end
  add_jumplist_for_move('move_in')
  operations.jump(target.node, target.row)
  add_jumplist_for_move('move_in')
end

---@return nil
function M.move_up()
  if util.is_markdown_file() then
    local current = anchor.current()
    local target, row = markdown_targets.find_up(current.node, current.row)
    if not target or not row then return end

    if confinement.should_confine(current.node, target) then
      return
    end

    local is_neighbor = current.row == row + 1 or current.row == row - 1

    if not is_neighbor then
      add_jumplist_for_move('move_up')
    end

    operations.jump(target, row)
    return
  end

  local current = anchor.current()
  local target = anchor.find_up(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  local is_neighbor = current.row == target.row + 1 or current.row == target.row - 1

  if not is_neighbor then
    add_jumplist_for_move('move_up')
  end

  operations.jump(target.node, target.row)
end

---@return nil
function M.move_down()
  if util.is_markdown_file() then
    local current = anchor.current()
    local target, row = markdown_targets.find_down(current.node, current.row)
    if not target or not row then return end

    if confinement.should_confine(current.node, target) then
      return
    end

    local is_neighbor = current.row == row + 1 or current.row == row - 1

    if not is_neighbor then
      add_jumplist_for_move('move_down')
    end

    operations.jump(target, row)

    if not is_neighbor then
      add_jumplist_for_move('move_down')
    end

    return
  end

  local current = anchor.current()
  local target = anchor.find_down(current)
  if not target then return end

  if confinement.should_confine(current.node, target.node) then
    return
  end

  local is_neighbor = current.row == target.row + 1 or current.row == target.row - 1

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end

  operations.jump(target.node, target.row)

  if not is_neighbor then
    add_jumplist_for_move('move_down')
  end
end

return M
