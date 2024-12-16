local nodes = require('treewalker.nodes')
local util = require('treewalker.util')
local ops = require('treewalker.ops')
local lines = require('treewalker.lines')
local strategies = require('treewalker.strategies')

local Treewalker = {}

---@alias Opts { highlight: boolean }

-- Default setup() options
---@type Opts
Treewalker.opts = {
  highlight = true
}

---@param opts Opts | nil
function Treewalker.setup(opts)
  if opts then
    Treewalker.opts = opts
  end
end

---@return nil
function Treewalker.move_out()
  local node = nodes.get_current()
  local target = strategies.get_first_ancestor_with_diff_scol(node)
  if not target then return end
  local row = target:range()
  row = row + 1
  ops.jump(row, target)
end

---@return nil
function Treewalker.move_in()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  --- Go down and in
  local candidate, candidate_row, candidate_line =
      strategies.get_down_and_in(current_row, current_col)

  -- Ultimate failure
  if not candidate_row or not candidate_line or not candidate then
    return --util.log("no in candidate")
  end

  ops.jump(candidate_row, candidate)
end

---@return nil
function Treewalker.move_up()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  -- Get next target if we're on an empty line
  local candidate, candidate_row, candidate_line =
      strategies.get_prev_if_on_empty_line(current_row, current_line)

  if candidate_row and candidate_line and candidate then
    return ops.jump(candidate_row, candidate)
  end

  --- Get next target at the same column
  candidate, candidate_row, candidate_line =
      strategies.get_neighbor_at_same_col("up", current_row, current_col)

  if candidate_row and candidate_line and candidate then
    return ops.jump(candidate_row, candidate)
  end

  -- Ultimate failure
  return --util.log("no up candidate")
end

---@return nil
function Treewalker.move_down()
  local current_row = vim.fn.line(".")
  local current_line = lines.get_line(current_row)
  local current_col = lines.get_start_col(current_line)

  -- Get next target if we're on an empty line
  local candidate, candidate_row, candidate_line =
      strategies.get_next_if_on_empty_line(current_row, current_line)

  if candidate_row and candidate_line and candidate then
    return ops.jump(candidate_row, candidate)
  end

  --- Get next target, if one is found
  candidate, candidate_row, candidate_line =
      strategies.get_neighbor_at_same_col("down", current_row, current_col)

  if candidate_row and candidate_line and candidate then
    return ops.jump(candidate_row, candidate)
  end

  -- Ultimate failure
  return --util.log("no down candidate")
end

return Treewalker
