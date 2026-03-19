local anchor = require "treewalker.anchor"
local operations = require "treewalker.operations"
local confinement = require "treewalker.confinement"
local markdown_targets = require "treewalker.markdown.targets"
local util = require "treewalker.util"

local M = {}

---@param current TreewalkerAnchor
---@param direction "find_up" | "find_down" | "find_in" | "find_out"
---@return TreewalkerAnchor | { node: TSNode, row: integer } | nil
local function find_target(current, direction)
  if util.is_markdown_file() then
    local node, row = markdown_targets[direction](current.node, current.row)
    if not node or not row then return nil end
    return { node = node, row = row }
  end

  return anchor[direction](current)
end

---@param target TreewalkerAnchor | { node: TSNode, row: integer }
local function jump_to(target)
  operations.jump(target.node, target.row)
end

---@param current TreewalkerAnchor
---@param target TreewalkerAnchor | { node: TSNode, row: integer }
---@return boolean
local function is_neighbor(current, target)
  return math.abs(current.row - target.row) == 1
end

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

  local current = anchor.current()
  local target = find_target(current, "find_out")
  if not target then
    operations.jump(current.node, current.row)
    return
  end

  jump_to(target)
  add_jumplist_for_move('move_out') -- for easy Ctrl-o/Ctrl-i navigation
end

---@return nil
function M.move_in()
  local current = anchor.current()
  local target = find_target(current, "find_in")
  if not target then return end

  add_jumplist_for_move('move_in')
  jump_to(target)
  add_jumplist_for_move('move_in')
end

---@return nil
function M.move_up()
  local current = anchor.current()
  local target = find_target(current, "find_up")
  if not target then return end

  if confinement.should_confine(current, target) then
    return
  end

  if not is_neighbor(current, target) then
    add_jumplist_for_move('move_up')
  end

  jump_to(target)
end

---@return nil
function M.move_down()
  local current = anchor.current()
  local target = find_target(current, "find_down")
  if not target then return end

  if confinement.should_confine(current, target) then
    return
  end

  local neighbor = is_neighbor(current, target)

  if not neighbor then
    add_jumplist_for_move('move_down')
  end

  jump_to(target)

  if not neighbor then
    add_jumplist_for_move('move_down')
  end
end

return M
