-- Script to check treesitter parser information
local languages = { 'typescript', 'java' }

print("Neovim version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
print("Treesitter module version: " .. vim.fn.system("nvim --version | head -1"):gsub("\n", ""))
print("")

for _, lang in ipairs(languages) do
  local ok, parser = pcall(vim.treesitter.language.get_lang, lang)
  if ok and parser then
    print(lang .. " parser: available")
    -- Try to get more info about the parser
    local parser_info = vim.treesitter.language.inspect(lang)
    if parser_info then
      print("  Symbols: " .. #parser_info.symbols)
    end
  else
    print(lang .. " parser: NOT available")
  end
end

print("")
print("nvim-treesitter installation:")
local ts_ok = pcall(require, 'nvim-treesitter.configs')
if ts_ok then
  print("  nvim-treesitter is loaded")
  local parsers = require('nvim-treesitter.parsers')
  for _, lang in ipairs(languages) do
    local parser_config = parsers.get_parser_configs()[lang]
    if parser_config then
      print("  " .. lang .. " parser config exists")
      if parser_config.install_info then
        print("    URL: " .. (parser_config.install_info.url or "unknown"))
        print("    Revision: " .. (parser_config.install_info.revision or "unknown"))
      end
    end
  end
else
  print("  nvim-treesitter NOT loaded")
end

-- Check actual installed parsers
print("")
print("Installed parser files:")
local parser_dir = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/parser'
for _, lang in ipairs(languages) do
  local parser_file = parser_dir .. '/' .. lang .. '.so'
  if vim.fn.filereadable(parser_file) == 1 then
    print("  " .. parser_file .. ": EXISTS")
    -- Get file modification time
    local stat = vim.loop.fs_stat(parser_file)
    if stat then
      print("    Modified: " .. os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec))
      print("    Size: " .. stat.size .. " bytes")
    end
  else
    print("  " .. parser_file .. ": NOT FOUND")
  end
end

vim.cmd('qa!')
