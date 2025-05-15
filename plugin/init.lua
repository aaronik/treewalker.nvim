local function tw()
  if os.getenv("TREEWALKER_NVIM_ENV") == "development" then
    -- For development. Makes the plugin auto-reload so you
    -- don't need to restart nvim to get the changes live.
    -- F*** it, we're doing it live!
    local util = require("treewalker.util")
    local initial_opts = require("treewalker").opts
    local treewalker = util.R("treewalker")
    treewalker.setup(initial_opts)
    return treewalker
  else
    return require("treewalker")
  end
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
  end,
}

local command_opts = {
  nargs = 1,
  complete = function(ArgLead)
    return vim.tbl_filter(function(cmd)
      return cmd:match("^" .. ArgLead)
    end, vim.tbl_keys(subcommands))
  end,
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
