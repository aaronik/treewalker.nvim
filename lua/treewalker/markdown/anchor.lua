local heading = require "treewalker.markdown.heading"
local nodes = require "treewalker.nodes"
local util = require "treewalker.util"

local M = {}

---@class MarkdownAnchor
---@field node TSNode
---@field section TSNode
---@field row integer
---@field heading_row integer
---@field level integer
---@field start integer
---@field finish integer
---@field is_heading boolean
---@field parent_row integer | nil

---@param row integer
---@return TSNode|nil
local function find_section_at_row(row)
  local root = nodes.get_root()
  if not root then return nil end

  local function traverse(node)
    if node:type() == "section" then
      local heading_row = heading.get_section_heading_row_and_node(node)
      local _, _, finish, _ = node:range()

      if heading_row and row >= heading_row and row <= finish then
        for child in node:iter_children() do
          local inner = traverse(child)
          if inner then return inner end
        end

        return node
      end
    end

    for child in node:iter_children() do
      local inner = traverse(child)
      if inner then return inner end
    end
  end

  return traverse(root)
end

---@param section TSNode
---@param row integer
---@return MarkdownAnchor | nil
local function build_anchor(section, row)
  local heading_row, heading_node = heading.get_section_heading_row_and_node(section)
  local level = heading.get_section_level(section)
  if not heading_row or not heading_node or not level then return nil end

  local _, _, finish, _ = section:range()
  local parent_row, _ = heading.find_parent_header(heading_row, level)
  local current_node = row == heading_row and heading_node or (nodes.get_at_row(row) or heading_node)

  return {
    node = current_node,
    section = section,
    row = row,
    heading_row = heading_row,
    level = level,
    start = heading_row,
    finish = finish,
    is_heading = row == heading_row,
    parent_row = parent_row,
  }
end

---@param row integer
---@return MarkdownAnchor | nil
function M.current(row)
  if not util.is_markdown_file() then return nil end

  local section = find_section_at_row(row)
  if not section then return nil end
  return build_anchor(section, row)
end

---@param row integer
---@return MarkdownAnchor | nil
function M.from_heading_row(row)
  local section = find_section_at_row(row)
  if not section then return nil end
  return build_anchor(section, row)
end

---@param row integer | nil
---@return MarkdownAnchor | nil
function M.current_heading(row)
  local current = M.current(row or vim.fn.line('.'))
  if not current or not current.is_heading then return nil end
  return current
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_next_same_level(current)
  local root = nodes.get_root()
  if not root then return nil end
  local found_current = false

  local _, target_row = heading.find_section_matching(root, function(_, section_row, section_level)
    if section_row and section_level == current.level then
      if found_current then
        return true
      elseif section_row == current.heading_row then
        found_current = true
      end
    end
    return false
  end)

  if not target_row then return nil end
  return M.from_heading_row(target_row)
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_prev_same_level(current)
  local root = nodes.get_root()
  if not root then return nil end
  local last_match = nil

  local _, target_row = heading.find_section_matching(root, function(_, section_row, section_level)
    if section_row and section_level == current.level then
      if section_row == current.heading_row then
        if last_match then
          return true, last_match
        end
        return false
      end

      last_match = section_row
    end
    return false
  end)

  if target_row then return M.from_heading_row(target_row) end
  return last_match and M.from_heading_row(last_match) or nil
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_nearest_prev(current)
  local root = nodes.get_root()
  if not root then return nil end
  local last_match = nil

  local _, target_row = heading.find_section_matching(root, function(_, section_row, _)
    if section_row and section_row < current.row then
      last_match = section_row
      return false
    elseif section_row and section_row >= current.row then
      return last_match ~= nil, last_match
    end
    return false
  end)

  if target_row then return M.from_heading_row(target_row) end
  return last_match and M.from_heading_row(last_match) or nil
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_nearest_next(current)
  local root = nodes.get_root()
  if not root then return nil end

  local _, target_row = heading.find_section_matching(root, function(_, section_row, _)
    return section_row and section_row > current.row
  end)

  if not target_row then return nil end
  return M.from_heading_row(target_row)
end

---@param child TSNode
---@param current MarkdownAnchor
---@return MarkdownAnchor | nil, boolean
local function child_anchor(child, current)
  if child:type() ~= "section" then return nil, false end

  local child_level = heading.get_section_level(child)
  local child_heading_row = heading.get_section_heading_row_and_node(child)
  if not child_level or not child_heading_row or child_level <= current.level then
    return nil, false
  end

  local anchor = M.from_heading_row(child_heading_row)
  if not anchor then return nil, false end

  return anchor, child_level == current.level + 1
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_in(current)
  if not current.is_heading then return nil end

  local fallback = nil

  for child in current.section:iter_children() do
    local anchor, exact_next_level = child_anchor(child, current)
    if anchor then
      if exact_next_level then
        return anchor
      end

      if not fallback then
        fallback = anchor
      end
    end
  end

  return fallback
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_out(current)
  if not current.is_heading then
    return M.from_heading_row(current.heading_row)
  end

  if current.level <= 1 then return nil end

  local root = nodes.get_root()
  if not root then return nil end
  local target_level = current.level - 1
  local best_match = nil

  local function traverse(node)
    if node:type() == "section" then
      local section_level = heading.get_section_level(node)
      local section_row = heading.get_section_heading_row_and_node(node)

      if section_row and section_level and section_row < current.heading_row and section_level <= target_level then
        if not best_match or section_row > best_match.row or
           (section_row == best_match.row and section_level > best_match.level) then
          best_match = { row = section_row, level = section_level }
        end
      end
    end

    for child in node:iter_children() do
      traverse(child)
    end
  end

  traverse(root)

  if not best_match then return nil end
  return M.from_heading_row(best_match.row)
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_up(current)
  if current.is_heading then
    return M.find_prev_same_level(current)
  end

  return M.find_nearest_prev(current)
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.find_down(current)
  if current.is_heading then
    return M.find_next_same_level(current)
  end

  return M.find_nearest_next(current)
end

---@param level integer
---@param parent_row integer | nil
---@param start_row integer
---@param end_row integer
---@return integer[]
local function sibling_rows(level, parent_row, start_row, end_row)
  local rows = {}

  for row = start_row, end_row do
    local info = heading.heading_info(row)
    if info.type == "heading" and info.level == level then
      local this_parent_row, _ = heading.find_parent_header(row, info.level)
      if this_parent_row == parent_row then
        table.insert(rows, row)
      end
    end
  end

  return rows
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.next_swappable_sibling(current)
  if not current.is_heading then return nil end

  local _, parent_start, parent_finish = heading.get_parent_section_bounds(current.heading_row, current.level)
  local start_row = current.parent_row == nil and 1 or (parent_start + 1)
  local rows = sibling_rows(current.level, current.parent_row, start_row, parent_finish)

  for index, row in ipairs(rows) do
    if row == current.heading_row then
      local next_row = rows[index + 1]
      return next_row and M.from_heading_row(next_row) or nil
    end
  end
end

---@param current MarkdownAnchor
---@return MarkdownAnchor | nil
function M.prev_swappable_sibling(current)
  if not current.is_heading then return nil end

  local _, parent_start, parent_finish = heading.get_parent_section_bounds(current.heading_row, current.level)
  local start_row = current.parent_row == nil and 1 or (parent_start + 1)
  local rows = sibling_rows(current.level, current.parent_row, start_row, parent_finish)

  for index, row in ipairs(rows) do
    if row == current.heading_row then
      local prev_row = rows[index - 1]
      return prev_row and M.from_heading_row(prev_row) or nil
    end
  end
end

return M
