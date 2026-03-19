local anchor = require "treewalker.anchor"
local markdown_anchor = require "treewalker.markdown.anchor"
local operations = require "treewalker.operations"
local confinement = require "treewalker.confinement"
local util = require "treewalker.util"

local M = {}

---@param current TreewalkerAnchor | MarkdownAnchor
---@param direction "find_up" | "find_down" | "find_in" | "find_out"
---@return TreewalkerAnchor | MarkdownAnchor | nil
local function find_target(current, direction)
  if util.is_markdown_file() then
    return markdown_anchor[direction](current)
  end

  return anchor[direction](current)
end

---@param target TreewalkerAnchor | { node: TSNode, row: integer }
local function jump_to(target)
  operations.jump(target.node, target.row)
end

---@param current TreewalkerAnchor | MarkdownAnchor
---@param target TreewalkerAnchor | MarkdownAnchor
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

---@return TreewalkerAnchor | MarkdownAnchor
local function current_anchor()
  if util.is_markdown_file() then
    local current = markdown_anchor.current(vim.fn.line('.'))
    assert(current, "Treewalker: Markdown heading not found under cursor")
    return current
  end

  return anchor.current()
end

---@return nil
function M.move_out()
  -- Add to jumplist at original cursor position before normalizing
  add_jumplist_for_move('move_out')

  local current = current_anchor()
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
  local current = current_anchor()
  local target = find_target(current, "find_in")
  if not target then return end

  add_jumplist_for_move('move_in')
  jump_to(target)
  add_jumplist_for_move('move_in')
end

---@return nil
function M.move_up()
  local current = current_anchor()
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
  local current = current_anchor()
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
