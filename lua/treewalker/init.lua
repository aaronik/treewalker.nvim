local nodes = require('treewalker.nodes')
local getters = require('treewalker.getters')
local util = require('treewalker.util')
local ops = require('treewalker.ops')
local lines = require('treewalker.lines')
local strategies = require('treewalker.strategies')

local M = {}

---@return nil
local function move_out()
  local node = getters.get_node()
  local target = getters.get_direct_ancestor(node)
  if not target then return end
  local row = target:range()
  ops.jump(row, target)
end

---@return nil
local function move_in()
  local node = getters.get_node()
  local target = getters.get_descendant(node)
  if not target then return end
  local row = target:range()
  ops.jump(row, target)
end

---@param row integer
---@param line string
---@param candidate TSNode
---@param prefix string
---@return nil
local function log(row, line, candidate, prefix)
  local col = lines.get_start_col(line)
  util.log(
    prefix .. ": [L " .. row .. ", I " .. col .. "] |" .. line .. "| [" .. candidate:type() .. "]" .. vim.inspect(nodes.range(candidate))
  )
end

---@return nil
local function move_up()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  --- Get next target, if one is found
  local candidate_row, candidate_line, candidate =
      strategies.get_next_vertical_target_at_same_col("up", current_row, current_col)

  -- Ultimate failure
  if not candidate_row or not candidate_line or not candidate then
    return util.log("no up candidate")
  end

  log(candidate_row, candidate_line, candidate, "move_up dest")
  ops.jump(candidate_row, candidate)
end

---@return nil
local function move_down()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  --- Get next target, if one is found
  local candidate_row, candidate_line, candidate =
      strategies.get_next_vertical_target_at_same_col("down", current_row, current_col)

  -- Ultimate failure
  if not candidate_row or not candidate_line or not candidate then
    return util.log("no down candidate")
  end

  log(candidate_row, candidate_line, candidate, "move_down dest")
  ops.jump(candidate_row, candidate)
end

function M.up() move_up() end

function M.down() move_down() end

function M.left() move_out() end

function M.right() move_in() end

return M

-- -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- -- you can also put some validation here for those.
-- local config = {}
-- M.config = config
-- M.setup = function(args)
--   M.config = vim.tbl_deep_extend("force", M.config, args or {})
-- end
