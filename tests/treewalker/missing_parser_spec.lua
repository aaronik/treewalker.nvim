local load_fixture = require("tests.load_fixture")
local assert = require("luassert")
local stub = require("luassert.stub")
local tw = require("treewalker")

local commands = {
  move_up = tw.move_up,
  move_down = tw.move_down,
  move_out = tw.move_out,
  move_in = tw.move_in,
  swap_up = tw.swap_up,
  swap_down = tw.swap_down,
  swap_left = tw.swap_left,
  swap_right = tw.swap_right,
}

describe("For a file in which there is a missing parser", function()
  before_each(function()
    load_fixture("/random.not_real", true)
    vim.opt.fileencoding = "utf-8"
  end)

  for nam, command in pairs(commands) do
    it(string.format("notifies once when %s is called", nam), function()
      local notify_once_stub = stub(vim, "notify_once")
      command()
      assert.stub(notify_once_stub).was.called(1)
    end)
  end
end)

describe("For a file in which there is a parser present", function()
  load_fixture("/lua.lua")

  for nam, command in pairs(commands) do
    it(string.format("does not notify when %s is called", nam), function()
      local notify_once_stub = stub(vim, "notify_once")
      command()
      assert.stub(notify_once_stub).was.called(0)
    end)
  end
end)
