-- local function tw()
--   -- Use this function for development. Makes the plugin auto-reload so you
--   -- don't need to restart nvim to get the changes.
--   local util = require "treewalker.util"
--   return util.R('treewalker')
-- end

local function tw()
  return require('treewalker')
end

local subcommands = {
  Up = function()
    tw().move_up()
  end,

  Left = function()
    tw().move_out()
  end,

  Down = function()
    tw().move_down()
  end,

  Right = function()
    tw().move_in()
  end,
  SelectUp = function()
    tw().select_up()
  end,

  SelectLeft = function()
    tw().select_out()
  end,

  SelectDown = function()
    tw().select_down()
  end,

  SelectRight = function()
    tw().select_in()
  end,

  SwapUp = function()
    tw().swap_up()
  end,

  SwapDown = function()
    tw().swap_down()
  end,

  SwapLeft = function()
    tw().swap_left()
  end,

  SwapRight = function()
    tw().swap_right()
  end
}

local command_opts = {
  nargs = 1,
  complete = function(ArgLead)
    return vim.tbl_filter(function(cmd)
      return cmd:match("^" .. ArgLead)
    end, vim.tbl_keys(subcommands))
  end
}

local function treewalker(opts)
  local subcommand = opts.fargs[1]
  if subcommands[subcommand] then
    subcommands[subcommand](vim.list_slice(opts.fargs, 2))
  else
    print("Unknown subcommand: " .. subcommand)
  end
end

vim.api.nvim_create_user_command("Treewalker", treewalker, command_opts)
