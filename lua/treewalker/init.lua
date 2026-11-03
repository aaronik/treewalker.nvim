local movement = require('treewalker.movement')
local swap = require('treewalker.swap')
local options = require('treewalker.options')

local Treewalker = {}

---@return boolean
local function has_parser()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  return ok and parser ~= nil
end

-- Default setup() options
---@type Opts
Treewalker.opts = {
  highlight = true,
  highlight_duration = 250,
  highlight_group = "CursorLine",
  jumplist = true,
  select = false,
  notifications = true,
  scope_confined = false,
}

-- This does not need to be called for Treewalker to work. The defaults are preinitialized and aim to be sane.
---@param opts OptsOverride | nil
function Treewalker.setup(opts)
  if opts == nil then return end -- nil is valid, in which case we stick to the defaults

  local is_opts_valid, validation_errors = options.validate_opts(opts)
  if not is_opts_valid and opts.notifications ~= false then
    return options.handle_opts_validation_errors(validation_errors)
  end

  Treewalker.opts = vim.tbl_deep_extend('force', Treewalker.opts, opts)
end

-- Makes sure the treesitter parser is available, otherwise makes a notification
-- Wrap a command to report a missing parser once.
---@param fn fun(opts: Opts): nil
---@return fun(opts?: OptsOverride): boolean
local function ensuring_parser(fn)
  ---@param overrides OptsOverride | nil
  ---@return boolean
  return function(overrides)
    local opts = Treewalker.opts
    if overrides ~= nil then
      opts = vim.tbl_deep_extend("force", {}, opts, overrides)
      local valid, errors = options.validate_opts(overrides)
      if not valid then
        if opts.notifications ~= false then
          options.handle_opts_validation_errors(errors)
        end
        return false
      end
    end

    local ft = vim.bo.ft
    if has_parser() then
      fn(opts)
      return true
    else
      if opts.notifications == false then
        return false
      end

      vim.notify_once(
        string.format(
          "Treewalker.nvim: Missing parser for files with extension [%s]! " ..
          "Treewalker won't work until one is installed.",
          ft
        ),
        vim.log.levels.ERROR
      )
      return false
    end
  end
end

Treewalker.up    = ensuring_parser(movement.move_up)
Treewalker.down  = ensuring_parser(movement.move_down)
Treewalker.left  = ensuring_parser(movement.move_out)
Treewalker.right = ensuring_parser(movement.move_in)

Treewalker.swap_up    = ensuring_parser(swap.swap_up)
Treewalker.swap_down  = ensuring_parser(swap.swap_down)
Treewalker.swap_right = ensuring_parser(swap.swap_right)
Treewalker.swap_left  = ensuring_parser(swap.swap_left)

-- In the plugin's past, the exposed lua API were these.
-- Although it was never documented, I'm sure some people had mapped straight
-- to these. Once the mappings became documented (when options were able
-- to be passed in), I wanted to conform the function names to the Ex
-- subcommand names. These four are here now for backwards compatibility
-- to anyone who may have mapped to them in the past.
-- TODO at some point put in a deprecation notification

---@deprecated Use up() instead.
Treewalker.move_up = Treewalker.up
---@deprecated Use down() instead.
Treewalker.move_down = Treewalker.down
---@deprecated Use left() instead.
Treewalker.move_out = Treewalker.left
---@deprecated Use right() instead.
Treewalker.move_in = Treewalker.right

return Treewalker
