local util = require("treewalker.util")
local stub = require('luassert.stub')
local assert = require("luassert")
local load_fixture = require("tests.load_fixture")

describe("util", function()
  describe("guid", function()
    it("never repeats", function()
      local guids = {}
      for _ = 1, 1000 do
        guids[util.guid()] = true
      end

      local count = 0
      for _ in pairs(guids) do
        count = count + 1
      end

      assert.equal(1000, count)
    end)

    it("has correct UUID v4 format", function()
      local guid = util.guid()
      -- UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      assert.equal(36, #guid)
      assert.equal("-", guid:sub(9, 9))
      assert.equal("-", guid:sub(14, 14))
      assert.equal("4", guid:sub(15, 15)) -- version 4
      assert.equal("-", guid:sub(19, 19))
      assert.equal("-", guid:sub(24, 24))
    end)

    it("generates valid hex characters", function()
      local guid = util.guid()
      local hex_chars = guid:gsub("-", "")
      assert.is_true(hex_chars:match("^[0-9a-f]+$") ~= nil)
    end)
  end)

  describe("log_file", function()
    it("works", function()
      local io_open_stub = stub.new(io, "open")

      ---@type string[]
      local writes = {}
      local num_flushes = 0
      local num_closes = 0

      local log_file = {
        -- _ is because write is a _method_, log_file:write, so it gets self arg
        write = function(_, arg1, arg2)
          table.insert(writes, arg1)
          table.insert(writes, arg2)
        end,
        flush = function()
          num_flushes = num_flushes + 1
        end,
        close = function()
          num_closes = num_closes + 1
        end
      }

      io_open_stub.returns(log_file)

      util.log_file(1, 2, 3, 4, 5)

      assert.same({ "1\n", "2\n", "3\n", "4\n", "5\n", }, writes)
      assert.equal(1, num_flushes)
      assert.equal(1, num_closes)
    end)

    it("handles table arguments", function()
      local io_open_stub = stub.new(io, "open")

      ---@type string[]
      local writes = {}

      local log_file = {
        write = function(_, arg1, _)
          table.insert(writes, arg1)
        end,
        flush = function() end,
        close = function() end
      }

      io_open_stub.returns(log_file)

      util.log_file({ foo = "bar" })

      assert.equal(1, #writes)
      assert.is_true(writes[1]:find("foo") ~= nil)
    end)

    it("handles nil log file gracefully", function()
      local io_open_stub = stub.new(io, "open")
      io_open_stub.returns(nil)

      -- Should not error
      util.log_file("test")
    end)
  end)

  describe("reverse", function()
    it("reverses an array table", function()
      local t = { 1, 2, 3, 4, 5 }
      local expected = { 5, 4, 3, 2, 1 }
      local reversed = util.reverse(t)
      assert.same(expected, reversed)
    end)

    it("handles empty tables", function()
      local t = {}
      local reversed = util.reverse(t)
      assert.same({}, reversed)
    end)

    it("handles single element tables", function()
      local t = { 1 }
      local reversed = util.reverse(t)
      assert.same({ 1 }, reversed)
    end)

    it("does not modify original table", function()
      local t = { 1, 2, 3 }
      util.reverse(t)
      assert.same({ 1, 2, 3 }, t)
    end)

    it("handles string elements", function()
      local t = { "a", "b", "c" }
      local reversed = util.reverse(t)
      assert.same({ "c", "b", "a" }, reversed)
    end)
  end)

  describe("is_markdown_file", function()
    it("returns true for markdown files", function()
      load_fixture("/markdown.md")
      assert.is_true(util.is_markdown_file())
    end)

    it("returns false for lua files", function()
      load_fixture("/lua.lua")
      assert.is_false(util.is_markdown_file())
    end)

    it("returns false for python files", function()
      load_fixture("/python.py")
      assert.is_false(util.is_markdown_file())
    end)

    it("returns false for javascript files", function()
      load_fixture("/javascript.js")
      assert.is_false(util.is_markdown_file())
    end)

    it("returns false for html files", function()
      load_fixture("/html.html")
      assert.is_false(util.is_markdown_file())
    end)
  end)

  describe("log", function()
    it("does not error with various input types", function()
      -- Just ensure these don't throw errors
      util.log("string")
      util.log(123)
      util.log(true)
      util.log({ key = "value" })
      util.log(nil)
    end)

    it("handles multiple arguments", function()
      -- Should not error
      util.log("one", "two", "three")
    end)
  end)
end)
