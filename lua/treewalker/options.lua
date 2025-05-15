local M = {}

---@alias Opts { highlight: boolean, highlight_duration: integer, highlight_group: string }

---@param opts Opts
---@return boolean, table<string>
function M.validate_opts(opts)
  local errors = {}

  if type(opts.highlight) ~= "boolean" and opts.highlight ~= nil then
    table.insert(errors, "`highlight` should be boolean or nil")
  end
  if type(opts.highlight_duration) ~= "number" and opts.highlight_duration ~= nil then
    table.insert(errors, "`highlight_duration` should be an integer or nil")
  end
  if type(opts.highlight_group) ~= "string" and opts.highlight_group ~= nil then
    table.insert(
      errors,
      "`highlight_group` should be a valid vim highlight-group or nil. See :h highlight-group for available options."
    )
  end

  if #errors == 0 then
    return true, {}
  else
    return false, errors
  end
end

function M.handle_opts_validation_errors(errors)
  local err_string = "Treewalker.nvim's setup() call has received incorrect option(s):\n"
  for _, msg in pairs(errors) do
    err_string = err_string .. "\n" .. msg
  end
  err_string = err_string .. "\n\nTreewalker.nvim will use the default options until all options are fixed."
  vim.notify(err_string, vim.log.levels.ERROR)
end

return M
