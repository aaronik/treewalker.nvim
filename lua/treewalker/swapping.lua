local nodes = require "treewalker.nodes"
local lines = require "treewalker.lines"
local strategies = require "treewalker.strategies"
local ops = require "treewalker.ops"
local targets = require "treewalker.targets"

local M = {}

---@return nil
function M.swap_out()
  local target, row, line = targets.out()
  if target and row and line then
    --util.log("no out candidate")
    ops.jump(row, target)
    return
  end
end

---@return nil
function M.swap_in()
  local target, row, line = targets.inn()

  if target and row and line then
    --util.log("no in candidate")
    ops.jump(row, target)
  end
end

---@param target TSNode
---@param row integer
---@param line string
local function swap(target, row, line)
  local current = nodes.get_current()
  current = nodes.get_highest_coincident(current)

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  local current_range = nodes.range(current)
  local target_range = nodes.range(target)

  ops.swap(
    { current_range[1], current_range[3] },
    { target_range[1], target_range[3] }
  )
end

---@return nil
function M.swap_down()
  local target, row, line = targets.down()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  swap(target, row, line)
end

---@return nil
function M.swap_up()
  local target, row, line = targets.up()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  swap(target, row, line)
end

return M
