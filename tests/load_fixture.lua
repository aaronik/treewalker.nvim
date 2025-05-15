local fixtures_dir = vim.fn.expand("tests/fixtures")

---@param filename string
---@return string
local function get_file_extension(filename)
  return filename:match(".+%.([^.]+)$")
end

-- Creates a buffer, and loads the contents of a specified filename into it.
-- Sets it as the current buffer
---@param filename string
---@param withhold_parsing true | nil
---@return integer
local function load_fixture(filename, withhold_parsing)
  local lang = get_file_extension(filename)
  local buf = vim.api.nvim_create_buf(false, true) -- Create a new buffer (listed) to enable interaction with it
  local lines = {}

  -- Read the file contents line by line and insert into the buffer
  for line in io.lines(fixtures_dir .. "/" .. filename) do
    table.insert(lines, line)
  end

  -- Set the lines into the created buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Focus on the buffer
  vim.api.nvim_set_current_buf(buf)

  -- Ensure the filetype is correctly set
  vim.bo.filetype = lang

  if not withhold_parsing then
    -- Get the parser and parse - error will be thrown if we don't have it
    vim.treesitter.get_parser(buf):parse(true)
  end

  return buf
end

return load_fixture
