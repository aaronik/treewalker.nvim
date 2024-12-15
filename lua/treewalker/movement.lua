local ops = require "treewalker.ops"
local targets = require "treewalker.targets"

local M = {}

---@return nil
function M.move_out()
  local target, row, line = targets.out()
  if target and row and line then
    --util.log("no out candidate")
    ops.jump(row, target)
    return
  end
end

---@return nil
function M.move_in()
  local target, row, line = targets.inn()

  if target and row and line then
    --util.log("no in candidate")
    ops.jump(row, target)
  end
end

---@return nil
function M.move_up()
  local target, row, line = targets.up()

  if target and row and line then
    --util.log("no up candidate")
    ops.jump(row, target)
  end
end

---@return nil
function M.move_down()
  local target, row, line = targets.down()

  if target and row and line then
    --util.log("no down candidate")
    ops.jump(row, target)
  end
end

return M
