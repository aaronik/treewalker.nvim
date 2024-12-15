local M = {}

---@param row integer
---@param line string
function M.set_line(row, line)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line })
end

---@param start integer
---@param endd integer
---@param lines string[]
function M.set_lines(start, endd, lines)
  vim.api.nvim_buf_set_lines(0, start - 1, endd - 1, false, lines)
end

---@param row integer
function M.get_line(row)
  return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
end

---@param start integer
---@param fin integer
function M.get_lines(start, fin)
  local lines = {}
  for row = start, fin, 1 do
    table.insert(lines, M.get_line(row))
  end
  return lines
end

---@param line string
---@return integer
function M.get_start_col(line)
  local tabwidth = vim.opt.tabstop:get()
  local count = 1 -- 1 indexed
  for i = 1, #line do
    local c = line:sub(i, i)
    if c == "\t" then
      count = math.floor((count + tabwidth) / tabwidth) * tabwidth
    elseif c == " " then
      count = count + 1
    else
      break
    end
  end
  return count
end

return M
