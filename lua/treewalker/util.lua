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

-- Log to the file debug.log in the plugin's data dir. File can be watched for easier debugging.
M.log_file = function(...)
	local args = { ... }

	-- Canonical log dir
	local data_path = vim.fn.stdpath("data") .. "/treewalker"

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
	if not log_file then
		return
	end

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

M.log = function(...)
	local args = { ... }
	for _, arg in ipairs(args) do
		if type(arg) == "table" then
			arg = vim.inspect(arg)
		end

		-- Use vim.api.nvim_echo to print without waiting for keypress
		vim.api.nvim_echo({ { tostring(arg) } }, true, {})
	end
end

M.guid = function()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end)
end

---reverse an array table
---@param t table
M.reverse = function(t)
	local reversed = {}
	for _, el in ipairs(t) do
		table.insert(reversed, 1, el)
	end
	return reversed
end

--- Returns true if current buffer's filetype is markdown
---@return boolean
M.is_markdown_file = function()
	local ft = (
		vim.bo and vim.bo.ft
		or (vim.api and vim.api.nvim_buf_get_option and vim.api.nvim_buf_get_option(0, "filetype"))
		or ""
	)
	return ft == "markdown" or ft == "md"
end

return M
