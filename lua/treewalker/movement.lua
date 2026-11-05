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
---@param opts Opts
local function jump_to(target, opts)
  operations.jump(target.node, target.row, opts)
end

-- Check whether a move crosses only one line.
---@param current TreewalkerAnchor | MarkdownAnchor
---@param target TreewalkerAnchor | MarkdownAnchor
---@return boolean
local function is_neighbor(current, target)
  return math.abs(current.row - target.row) == 1
end

---@param command string
---@param opts Opts
---@return boolean
local function should_add_jumplist(command, opts)
  local jumplist = opts.jumplist

  if jumplist == false then return false end

  -- Only 'move_out' (left) jumps get jumplist in 'left' mode
  if jumplist == 'left' then
    return command == 'move_out'
  end

  return true
end

---@param command string
---@param opts Opts
local function add_jumplist_for_move(command, opts)
  if should_add_jumplist(command, opts) then
    vim.cmd("normal! m'")
  end
end

-- Create the appropriate anchor at the cursor.
---@return TreewalkerAnchor | MarkdownAnchor | nil
local function current_anchor()
  if util.is_markdown_file() then
    return markdown_anchor.current(vim.fn.line('.'))
  end

  return anchor.current()
end

---@param opts Opts
---@return nil
function M.move_out(opts)
  local current = current_anchor()
  if not current then return end

  -- Add to jumplist at original cursor position before normalizing
  add_jumplist_for_move('move_out', opts)

  local target = find_target(current, "find_out")
  if not target then
    operations.jump(current.node, current.row, opts)
    return
  end

  jump_to(target, opts)
  add_jumplist_for_move('move_out', opts) -- for easy Ctrl-o/Ctrl-i navigation
end

---@param opts Opts
---@return nil
function M.move_in(opts)
  local current = current_anchor()
  if not current then return end

  local target = find_target(current, "find_in")
  if not target then return end
  if opts.scope_confined and not util.is_markdown_file()
    and not vim.treesitter.is_ancestor(current.node, target.node) then return end

  add_jumplist_for_move('move_in', opts)
  jump_to(target, opts)
  add_jumplist_for_move('move_in', opts)
end

---@param opts Opts
---@return nil
function M.move_up(opts)
  local current = current_anchor()
  if not current then return end
  local target = find_target(current, "find_up")
  if not target then return end

  if confinement.should_confine(current, target, opts) then
    return
  end

  if not is_neighbor(current, target) then
    add_jumplist_for_move('move_up', opts)
  end

  jump_to(target, opts)
end

---@param opts Opts
---@return nil
function M.move_down(opts)
  local current = current_anchor()
  if not current then return end
  local target = find_target(current, "find_down")
  if not target then return end

  if confinement.should_confine(current, target, opts) then
    return
  end

  local neighbor = is_neighbor(current, target)

  if not neighbor then
    add_jumplist_for_move('move_down', opts)
  end

  jump_to(target, opts)

  if not neighbor then
    add_jumplist_for_move('move_down', opts)
  end
end

return M
