local assert = require("luassert")
local load_fixture = require("tests.load_fixture")
local stub = require("luassert.stub")
local tw = require("treewalker")

---@class TreewalkerCommandCase
---@field name string
---@field run fun(): boolean

---@type TreewalkerCommandCase[]
local command_cases = {
  { name = "move_up", run = tw.move_up },
  { name = "move_down", run = tw.move_down },
  { name = "move_out", run = tw.move_out },
  { name = "move_in", run = tw.move_in },
  { name = "swap_up", run = tw.swap_up },
  { name = "swap_down", run = tw.swap_down },
  { name = "swap_left", run = tw.swap_left },
  { name = "swap_right", run = tw.swap_right },
}

-- This is how nvim 11 and before does things
---@param command fun(): boolean
---@param expected_notify_count integer
local function assert_missing_parser_behavior_with_throws(command, expected_notify_count)
  local get_parser_stub = stub.new(vim.treesitter, "get_parser")
  local notify_once_stub = stub.new(vim, "notify_once")

  get_parser_stub.invokes(function()
    error("missing parser")
  end)

  local ok, return_val = pcall(command)
  local notify_count = #notify_once_stub.calls

  get_parser_stub:revert()
  notify_once_stub:revert()

  assert.same(true, ok)
  assert.equal(expected_notify_count, notify_count)
  assert.same(false, return_val)
end

-- This is how nvim 12 does things (wonder why they changed it?)
---@param command fun(): boolean
---@param expected_notify_count integer
local function assert_missing_parser_behavior_with_nil_lookup(command, expected_notify_count)
  local get_parser_stub = stub.new(vim.treesitter, "get_parser")
  local notify_once_stub = stub.new(vim, "notify_once")

  get_parser_stub.returns(nil)

  local ok, return_val = pcall(command)
  local notify_count = #notify_once_stub.calls

  get_parser_stub:revert()
  notify_once_stub:revert()

  assert.same(true, ok)
  assert.equal(expected_notify_count, notify_count)
  assert.same(false, return_val)
end

---@param command fun(): boolean
local function assert_present_parser_behavior(command)
  local notify_once_stub = stub.new(vim, "notify_once")
  local ok, return_val = pcall(command)
  local notify_count = #notify_once_stub.calls

  notify_once_stub:revert()

  assert.same(true, ok)
  assert.equal(0, notify_count)
  assert.same(true, return_val)
end

describe("When a parser is present", function()
  before_each(function()
    load_fixture("/lua.lua")
    tw.setup({ notifications = true })
  end)

  for _, case in ipairs(command_cases) do
    it(string.format("does not notify and returns true when %s is called", case.name), function()
      assert_present_parser_behavior(case.run)
    end)
  end
end)

describe("When a parser is missing and parser lookup raises (Neovim 11)", function()
  describe("when notifications are enabled", function()
    before_each(function()
      load_fixture("/random.not_real", true)
      vim.opt.fileencoding = "utf-8"
      tw.setup({ notifications = true })
    end)

    for _, case in ipairs(command_cases) do
      it(string.format("notifies once and returns false when %s is called", case.name), function()
        assert_missing_parser_behavior_with_throws(case.run, 1)
      end)
    end
  end)

  describe("when notifications are disabled", function()
    before_each(function()
      load_fixture("/random.not_real", true)
      vim.opt.fileencoding = "utf-8"
      tw.setup({ notifications = false })
    end)

    for _, case in ipairs(command_cases) do
      it(string.format("does not notify and returns false when %s is called", case.name), function()
        assert_missing_parser_behavior_with_throws(case.run, 0)
      end)
    end
  end)
end)

describe("When a parser is missing and parser lookup returns nil (Neovim 12)", function()
  describe("when notifications are enabled", function()
    before_each(function()
      load_fixture("/random.not_real", true)
      vim.opt.fileencoding = "utf-8"
      tw.setup({ notifications = true })
    end)

    for _, case in ipairs(command_cases) do
      it(string.format("notifies once and returns false when %s is called", case.name), function()
        assert_missing_parser_behavior_with_nil_lookup(case.run, 1)
      end)
    end
  end)

  describe("when notifications are disabled", function()
    before_each(function()
      load_fixture("/random.not_real", true)
      vim.opt.fileencoding = "utf-8"
      tw.setup({ notifications = false })
    end)

    for _, case in ipairs(command_cases) do
      it(string.format("does not notify and returns false when %s is called", case.name), function()
        assert_missing_parser_behavior_with_nil_lookup(case.run, 0)
      end)
    end
  end)
end)
