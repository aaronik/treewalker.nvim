-- Utility functions
local M = {}

-- remove program code from lua cache, reload
M.RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

-- modified 'require'; use to flush entire program from top level for plugin development.
M.R = function(name)
  M.RELOAD(name)
  return require(name)
end

-- print tables contents
M.P = function(v)
  print(vim.inspect(v))
  return v
end

-- Log to the file debug.log in the root. File can be watched for easier debugging.
M.log = function(...)
  local args = { ... }

  -- Canonical log dir
  local data_path = vim.fn.stdpath("data") .. "/gptmodels"

  -- If no dir on fs, make it
  if vim.fn.isdirectory(data_path) == 0 then
    vim.fn.mkdir(data_path, "p")
  end

  local log_file = io.open(data_path .. "/debug.log", "a")

  -- Guard against no log file by making one
  if not log_file then
    log_file = io.open(data_path .. "/debug.log", "w+")
  end

  -- Swallow further errors
  -- This is a utility for development, it should never cause issues
  -- during real use.
  if not log_file then return end

  -- Write each arg to disk
  for _, arg in ipairs(args) do
    if type(arg) == "table" then
      arg = vim.inspect(arg)
    end

    log_file:write(tostring(arg) .. "\n")
  end

  log_file:flush() -- Ensure the output is written immediately
  log_file:close()
end

---@param lines string[]
---@param string string
M.contains = function(lines, string)
  local found_line = false
  for _, line in ipairs(lines) do
    if line == string then
      found_line = true
      break
    end
  end
  return found_line
end

--- Merging multiple tables into one. Works on both map like and array like tables.
--- This function accepts variadic arguments (multiple tables)
--- It merges keys from the provided tables into a new table.
--- @generic T
--- @param ... T - Any number of tables to merge.
--- @return T - A new merged table of the same type as the input tables.
M.merge_tables = function(...)
  local new_table = {}

  for _, t in ipairs({ ... }) do
    for k, v in pairs(t) do
      if type(k) == "number" then
        table.insert(new_table, v)
      else
        new_table[k] = v
      end
    end
  end

  return new_table
end

M.guid = function()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

---reverse an array table
---@param t table
M.reverse = function (t)
  local reversed = {}
  for _, el in ipairs(t) do
    table.insert(reversed, 1, el)
  end
  return reversed
end

return M
