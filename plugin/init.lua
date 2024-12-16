local function tw()
  -- local util = require "treewalker.util"
  -- return util.R('treewalker')
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
  end
}

local command_opts = {
  nargs = 1,
  complete = function(ArgLead, CmdLine, CursorPos)
    return vim.tbl_filter(function(cmd)
      return cmd:match("^" .. ArgLead)
    end, vim.tbl_keys(subcommands))
  end
}

function Treewalker(opts)
  local subcommand = opts.fargs[1]
  if subcommands[subcommand] then
    subcommands[subcommand](vim.list_slice(opts.fargs, 2))
  else
    print("Unknown subcommand: " .. subcommand)
  end
end

vim.api.nvim_create_user_command("Treewalker", Treewalker, command_opts)
