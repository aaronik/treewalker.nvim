local util = require "treewalker.util"
local heading = require "treewalker.markdown.heading"
local nodes = require "treewalker.nodes"
local ast_utils = require "treewalker.markdown.ast_utils"

local M = {}

--- Find the section node containing the given row
---@param row integer
---@return TSNode|nil
local function find_section_at_row(row)
  local node = nodes.get_at_row(row)
  if not node then return nil end

  local current = node --[[@as TSNode?]]
  while current do
    if current:type() == "section" then
      return current
    end
    current = current:parent()
  end
  return nil
end

-- Use shared utilities for section operations
local get_section_level = ast_utils.get_section_level
local get_section_heading_row_and_node = ast_utils.get_section_heading_row_and_node
local function get_section_heading_row(section_node)
  local row, _ = get_section_heading_row_and_node(section_node)
  return row
end

--- Find next sibling section at the same level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then return nil, nil end

  local current_level = heading.heading_level(row)
  if not current_level then return nil, nil end

  -- Use treesitter to walk through all sections in document order
  local root = vim.treesitter.get_parser():parse()[1]:root()
  local found_current = false

  local function find_in_node(node)
    if node:type() == "section" then
      local section_level = get_section_level(node)
      local section_row = get_section_heading_row(node)

      if section_row and section_level == current_level then
        if found_current then
          local section_row_new, heading_node = get_section_heading_row_and_node(node)
          return heading_node, section_row_new
        elseif section_row == row then
          found_current = true
        end
      end
    end

    -- Recursively search children
    for child in node:iter_children() do
      local result_node, result_row = find_in_node(child)
      if result_node then return result_node, result_row end
    end

    return nil, nil
  end

  local result_node, result_row = find_in_node(root)
  return result_node, result_row
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_same_level_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then
    return M.get_nearest_prev_heading(row)
  end

  local current_level = heading.heading_level(row)
  if not current_level then return nil, nil end

  -- Use treesitter to walk through all sections in document order
  local root = vim.treesitter.get_parser():parse()[1]:root()
  local last_match = nil

  local function find_in_node(node)
    if node:type() == "section" then
      local section_level = get_section_level(node)
      local section_row = get_section_heading_row(node)

      if section_row and section_level == current_level then
        if section_row == row then
          -- Found current, return the last match we found
          return last_match and nodes.get_at_row(last_match), last_match
        else
          -- Update last match
          last_match = section_row
        end
      end
    end

    -- Recursively search children
    for child in node:iter_children() do
      local result_node, result_row = find_in_node(child)
      if result_node then return result_node, result_row end
    end

    return nil, nil
  end

  local result_node, result_row = find_in_node(root)
  return result_node, result_row
end

-- Find nearest prev heading at any level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_prev_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  local root = vim.treesitter.get_parser():parse()[1]:root()
  local last_match = nil

  local function find_in_node(node)
    if node:type() == "section" then
      local section_row = get_section_heading_row(node)
      if section_row and section_row < row then
        last_match = section_row
      elseif section_row and section_row >= row then
        return last_match and nodes.get_at_row(last_match), last_match
      end
    end

    for child in node:iter_children() do
      local result_node, result_row = find_in_node(child)
      if result_node then return result_node, result_row end
    end

    return nil, nil
  end

  local result_node, result_row = find_in_node(root)
  if result_node then return result_node, result_row end
  return last_match and nodes.get_at_row(last_match), last_match
end

-- Find nearest next heading at any level
---@param row integer
---@return TSNode | nil, integer | nil
function M.get_nearest_next_heading(row)
  if not util.is_markdown_file() then return nil, nil end

  local root = vim.treesitter.get_parser():parse()[1]:root()

  local function find_in_node(node)
    if node:type() == "section" then
      local section_row = get_section_heading_row(node)
      if section_row and section_row > row then
        return nodes.get_at_row(section_row), section_row
      end
    end

    for child in node:iter_children() do
      local result_node, result_row = find_in_node(child)
      if result_node then return result_node, result_row end
    end

    return nil, nil
  end

  return find_in_node(root)
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_next_inner_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then return nil, nil end

  local section = find_section_at_row(row)
  if not section then return nil, nil end

  local current_level = get_section_level(section)
  if not current_level then return nil, nil end

  -- Find first child section with level current_level + 1
  for child in section:iter_children() do
    if child:type() == "section" then
      local child_level = get_section_level(child)
      if child_level == current_level + 1 then
        local heading_row = get_section_heading_row(child)
        if heading_row then
          return nodes.get_at_row(heading_row), heading_row
        end
      end
    end
  end

  return nil, nil
end

---@param row integer
---@return TSNode | nil, integer | nil
function M.get_prev_outer_heading(row)
  if not util.is_markdown_file() then return nil, nil end
  if not heading.is_heading(row) then return nil, nil end

  local current_level = heading.heading_level(row)
  if not current_level or current_level <= 1 then return nil, nil end

  -- For out-of-order headings, we need to find the nearest previous heading
  -- with a lower level (not necessarily direct AST parent)
  local root = vim.treesitter.get_parser():parse()[1]:root()
  local target_level = current_level - 1
  local best_match = nil

  local function find_in_node(node)
    if node:type() == "section" then
      local section_level = get_section_level(node)
      local section_row = get_section_heading_row(node)

      if section_row and section_row < row and section_level and section_level <= target_level then
        -- Update best match if this is closer or has a higher level (but still <= target_level)
        if not best_match or section_row > best_match.row or
           (section_row == best_match.row and section_level > best_match.level) then
          best_match = { row = section_row, level = section_level }
        end
      end
    end

    -- Recursively search children
    for child in node:iter_children() do
      find_in_node(child)
    end
  end

  find_in_node(root)

  if best_match then
    return nodes.get_at_row(best_match.row), best_match.row
  end

  return nil, nil
end

return M
