local nodes = require "treewalker.nodes"
local ops = require "treewalker.ops"
local targets = require "treewalker.targets"

local M = {}

---@return nil
function M.swap_down()
  local target, row, line = targets.down()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  local current = nodes.get_current()
  local current_range = nodes.range(current)
  local current_rows = { current_range[1], current_range[3] }

  local target_range = nodes.range(target)
  local target_rows = { target_range[1], target_range[3] }

  ops.swap(current_rows, target_rows)

  -- Place cursor
  local node_length_diff = ((current_range[3] - current_range[1]) + 1) - ((target_range[3] - target_range[1]) + 1)
  vim.fn.cursor(target_range[1] - node_length_diff + 1, target_range[2] + 1)
end

---@return nil
function M.swap_up()
  local target, row, line = targets.up()

  if not target or not row or not line then
    --util.log("no down candidate")
    return
  end

  local current = nodes.get_current()
  local current_range = nodes.range(current)
  local current_rows = { current_range[1], current_range[3] }

  local target_range = nodes.range(target)
  local target_rows = { target_range[1], target_range[3] }

  ops.swap(target_rows, current_rows)

  -- Place cursor
  vim.fn.cursor(target_range[1] + 1, target_range[2] + 1)
end

return M
