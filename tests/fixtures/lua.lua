local M = {}

local NON_TARGET_NODE_MATCHERS = {
  -- "chunk", -- lua
  "^.*comment.*$",
}

local TARGET_DESCENDANT_TYPES = {
  "body_statement",  -- lua, rb
  "block",           -- lua
  "statement_block", -- lua

  -- "then", -- helps rb, hurts lua
  "do_block", -- rb
}

---@param node TSNode
---@return boolean
local function is_jump_target(node)
  for _, matcher in ipairs(NON_TARGET_NODE_MATCHERS) do
    if node:type():match(matcher) then
      return false
    end
  end
  return true
end

local function is_descendant_jump_target(node)
  return vim.list_contains(TARGET_DESCENDANT_TYPES, node:type())
end

---Do the nodes have the same starting point
---@param node1 TSNode
---@param node2 TSNode
---@return boolean
local function have_same_range(node1, node2)
  local srow1, scol1 = node1:range()
  local srow2, scol2 = node2:range()
  return
      srow1 == srow2 and
      scol1 == scol2
end

---Strictly sibling, no fancy business
---@param node TSNode
---@return TSNode | nil
local function get_prev_sibling(node)
  local iter_sibling = node:prev_sibling()

  while iter_sibling do
    if is_jump_target(iter_sibling) then
      return iter_sibling
    end

    iter_sibling = iter_sibling:prev_sibling()
  end
end

---Strictly sibling, no fancy business
---@param node TSNode
---@return TSNode | nil
local function get_next_sibling(node)
  local iter_sibling = node:next_sibling()

  while iter_sibling do
    if is_jump_target(iter_sibling) then
      return iter_sibling
    end

    iter_sibling = iter_sibling:next_sibling()
  end
end

---Get _next_ or _out and next_
---@param node TSNode
---@return TSNode | nil
function M.get_next(node)
  local next_sibling = get_next_sibling(node)

  if next_sibling then
    return next_sibling
  end

  -- No next sibling jump target is found
  -- Travel up the tree to find the next parent's sibling
  local ancestor = M.get_direct_ancestor(node)
  if ancestor then
    return M.get_next(ancestor)
  end

  return nil
end

---This one goes _prev_ or _out_
---@param node TSNode
---@return TSNode | nil
function M.get_prev(node)
  local prev_sibling = get_prev_sibling(node)
  if prev_sibling then
    return prev_sibling
  end

  -- If we reach a dead end, climb up a level
  return M.get_direct_ancestor(node)
end

---Get the nearest ancestral node _which has different coordinates than the passed in node_
---@param node TSNode
---@return TSNode | nil
function M.get_direct_ancestor(node)
  local iter_ancestor = node:parent()
  while iter_ancestor do
    -- Without have_same_range, this will get stuck, where it targets one node, but is then
    -- interpreted by get_node() as another.
    if is_jump_target(iter_ancestor) and not have_same_range(node, iter_ancestor) then
      return iter_ancestor
    end

    iter_ancestor = iter_ancestor:parent()
  end
end

---helper to get all the children from a node
---@param node TSNode
---@return TSNode[]
local function get_children(node)
  local children = {}
  local iter = node:iter_children()
  local child = iter()
  while child do
    table.insert(children, child)
    child = iter()
  end
  return children
end

---Get the next target descendent
---The idea here is it goes _in_ or _down and in_
---@param node TSNode
---@return TSNode | nil
function M.get_descendant(node)
  local queue = get_children(node)

  while #queue > 0 do
    local current_node = table.remove(queue, 1)
    if is_descendant_jump_target(current_node) then
      return current_node
    end

    local iter = current_node:iter_children()
    local child = iter()
    while child do
      table.insert(queue, child)
      child = iter()
    end
  end

  -- If there was nothing below us, try below a sibling
  local next_sibling = node:next_sibling()
  if next_sibling then
    return M.get_descendant(next_sibling)
  end

  -- If there were no nephews, try children of an uncle (final recursive step to get at the whole tree)
  local parent = node:parent()
  if not parent then return nil end
  local uncle = parent:next_sibling()
  if not uncle then return nil end

  return M.get_descendant(uncle)
end

---Get current node under cursor
---@return TSNode
function M.get_node()
  --This comment to test that this line isn't landed on in a move right
  local node = vim.treesitter.get_node()
  assert(node)

  return node
end

return M

-- This is a lua fixture. I thought I was being smart when I got it
-- from this plugin. But actually I was being dumb, and this is very confusing, l0lz
