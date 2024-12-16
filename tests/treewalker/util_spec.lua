local util = require("treewalker.util")
local stub = require('luassert.stub')
local assert = require("luassert")

describe("util", function()
  describe("contains_line", function()
    assert(util.contains({ "has", "also" }, "has"))
    assert.False(util.contains({ "doesnt" }, "has"))
  end)

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
  end)

  describe("log", function()
    it("works", function()
      local io_open_stub = stub(io, "open")

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

      util.log(1, 2, 3, 4, 5)

      assert.same({ "1\n", "2\n", "3\n", "4\n", "5\n", }, writes)
      assert.equal(1, num_flushes)
      assert.equal(1, num_closes)
    end)
  end)

  describe("merge_tables", function()
    it("merges N hash style tables", function()
      local a = { a = true }
      local b = { b = true }
      local c = { c = true }
      local d = util.merge_tables(a, b, c)
      assert.same({ a = true, b = true, c = true }, d)
    end)

    it("merges multiple array style tables", function()
      local a = { true }
      local b = { false }
      local c = { true, false }
      local d = util.merge_tables(a, b, c)
      assert.same({ true, false, true, false }, d)
    end)

    it("merges combo style tables", function()
      local a = { a = true }
      local b = { false, false }
      local c = { true, true }
      local d = util.merge_tables(a, b, c)
      assert.same({ a = true, false, false, true, true }, d)
    end)

    it("does not overwrite arguments", function()
      local a = { a = true }
      local b = { b = true }
      util.merge_tables(a, b)
      assert.same({ a = true }, a)
      assert.same({ b = true }, b)
    end)
  end)

  describe("reverse", function()
    it("reverses an array table", function()
      local t = { 1, 2, 3, 4, 5 }
      local expected = { 5, 4, 3, 2, 1 }
      local reversed = util.reverse(t)
      assert.same(expected, reversed)
    end)
  end)
end)
