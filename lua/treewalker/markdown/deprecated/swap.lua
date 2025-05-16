--[[
  DEPRECATION NOTICE:
  This file provides a backward compatibility layer for Treewalker.nvim users
  who invoke 'require("treewalker.markdown.swap")'.

  All deprecated interface or compatibility glue modules for markdown should live
  in this directory: 'lua/treewalker/markdown/deprecated/'.

  Policy: Only preserve this file while downstream dependencies might still load
  the old require path. Remove after the next major release/compat window expires.

  See: 'lua/treewalker/markdown/swap/section.lua' for the new implementation.
--]]

local deprecation = require('treewalker.markdown.swap.deprecation')

return deprecation.deprecate_module(
  'treewalker.markdown.swap',
  "[treewalker] 'markdown/swap.lua' is deprecated, use 'markdown/swap/section.lua' instead",
  'treewalker.markdown.swap.section'
)
