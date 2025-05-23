-- Markdown heading/section/relationship API for Treewalker.nvim
-- Unified and extensible: uses Treesitter AST when available, or falls back to line parsing

local util = require "treewalker.util"
local lines = require "treewalker.lines"
local nodes = require "treewalker.nodes"

local M = {}

------------------------------------------------------------
-- Heading info extraction: Prefer Treesitter AST, fallback to line regex
------------------------------------------------------------

-- Check if what looks like a header is actually a sneaky comment
-- in a code fence
---@param row integer
---@return boolean
local function is_code_comment(row)
  local line_node = nodes.get_at_row(row)
  if not line_node then return false end

  if line_node:type() == "comment" then
    return true
  end

  return false
end

--- Classify heading by examining the raw line (ATX, setext/underline style, etc)
---@param row integer
---@return {type: string, level: integer}|{type: string}
local function line_heading_info(row)
  local line = lines.get_line(row) or ""

  -- Don't treat lines inside code fences as headings
  if is_code_comment(row) then
    return { type = "none" }
  end

  local atx = line:match("^(#+)%s")
  if atx then
    return { type = "heading", level = #atx }
  end
  -- Support underline-style headers (===/---)
  if row > 1 then
    local prev = lines.get_line(row - 1) or ""
    if prev:find("%S") then
      local underline = line:match("^([=-]{3,})%s*$")
      if underline then
        local level = underline:find("=") and 1 or 2
        return { type = "heading", level = level }
      end
    end
  end
  return { type = "none" }
end

--- Unified heading info extraction
---@param row integer
---@return {type: string, level?: integer}
function M.heading_info(row)
  -- In future: try Treesitter, fallback to lines. Today: lines only.
  return line_heading_info(row) or { type = "none" }
end

--- Returns heading level for a row or nil if not on heading
---@param row integer
function M.heading_level(row)
  local info = M.heading_info(row)
  return info.type == "heading" and info.level or nil
end

--- Does this row contain a heading?
---@param row integer
function M.is_heading(row)
  local info = M.heading_info(row)
  return info.type == "heading"
end

------------------------------------------------------------
-- Heading relationships (siblings, parent, child)
------------------------------------------------------------

--- Are two rows headings at the same level?
---@param row1 integer
---@param row2 integer
function M.is_sibling(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h1.level == h2.level
end

--- Is row1 the parent heading of row2?
---@param row1 integer
---@param row2 integer
function M.is_parent(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h2.level == h1.level - 1
end

--- Is row1 the child heading of row2?
---@param row1 integer
---@param row2 integer
function M.is_child(row1, row2)
  local h1, h2 = M.heading_info(row1), M.heading_info(row2)
  return h1.type == "heading" and h2.type == "heading" and h2.level == h1.level + 1
end

------------------------------------------------------------
-- Section detection utilities (bounds etc)
------------------------------------------------------------

--- Returns (level, start_row, end_row) for the section containing row.
---@param row integer
function M.get_section_bounds(row)
  if not util.is_markdown_file() then return nil, nil, nil end
  local info = M.heading_info(row)
  if info.type ~= "heading" then return nil, nil, nil end
  local level = info.level
  local start_row = row
  local end_row = nil
  local max_row = vim.api.nvim_buf_line_count(0)
  for next_row = row + 1, max_row do
    local next_info = M.heading_info(next_row)
    if next_info.type == "heading" and next_info.level <= level then
      end_row = next_row - 1
      break
    end
  end
  if not end_row then
    end_row = max_row
  end
  return level, start_row, end_row
end

--- Finds the parent heading row and its level for a heading at row.
---@param row integer
---@param level integer
function M.find_parent_header(row, level)
  for r = row - 1, 1, -1 do
    local info = M.heading_info(r)
    if info.type == "heading" and info.level < level then
      return r, info.level
    end
  end
  return nil, nil
end

--- Returns the section bounds of the parent heading.
---@param row integer
---@param level integer
function M.get_parent_section_bounds(row, level)
  local parent_row, parent_level = M.find_parent_header(row, level)
  if parent_row and parent_level then
    return M.get_section_bounds(parent_row)
  end
  return nil, 1, vim.api.nvim_buf_line_count(0)
end

return M
