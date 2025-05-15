-- This spec ensures there's nowhere in the code that calls undesirable
-- util functions like R and log. This isn't perfect, as it tries to exercise
-- each command, but doesn't seek edge cases.

local load_fixture = require("tests.load_fixture")
local assert = require("luassert")
local stub = require("luassert.stub")
local util = require("treewalker.util")

local commands = {
  "Treewalker Up",
  "Treewalker Down",
  "Treewalker Right",
  "Treewalker Left",
  "Treewalker SwapUp",
  "Treewalker SwapDown",
  "Treewalker SwapRight",
  "Treewalker SwapLeft",
}

-- can't get luassert (plenary) spy working
-- This needs to be generic over obj but can't figure out that either
---@param obj table
---@param method string
local function spy(obj, method)
  local orig = obj[method]
  local stoob = stub(obj, method)
  stoob.callback = orig
  ---@type type obj
  return stoob
end

describe("Extent util calls:", function()
  local util_R_stub = spy(util, "R")
  local util_log_stub = spy(util, "log")

  -- Simulate TREEWALKER_NVIM_ENV being set to anything other than "development", see plugin/init.lua
  stub(os, "getenv").returns("")

  before_each(function()
    load_fixture("/lua.lua")
    vim.opt.fileencoding = "utf-8"
    vim.fn.cursor(31, 26)
  end)

  for _, command in ipairs(commands) do
    it(command .. " encounters no " .. "util.R calls", function()
      vim.cmd(command)
      assert.stub(util_R_stub).was.called(0)
    end)

    it(command .. " encounters no " .. "util.log calls", function()
      vim.cmd(command)
      assert.stub(util_log_stub).was.called(0)
    end)
  end
end)
