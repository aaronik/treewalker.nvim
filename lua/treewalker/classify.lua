-- These are regexes but just happen to be real simple so far
local TARGET_BLACKLIST_TYPE_MATCHERS = {
  "comment",
  "source",             -- On Ubuntu, on nvim 0.11, TS is diff for comments, with source as the child of comment
  "text",               -- Same as above but with java
  "attribute_item",     -- decorators (rust)
  "decorat",            -- decorators (py)
  "else",               -- else/elseif statements (lua)
  "elif",               -- else/elseif statements (py)
  "end_tag",            -- html closing tags
  "declaration_list",   -- C# class blocks
  "compound_statement", -- C blocks when defined under their fn names like a psycho
  "c_sharp:block",      -- C# block nodes (language-specific)
  "haskell:imports",    -- Haskell top-level import collection
  "haskell:declarations", -- Haskell top-level declaration collection
}

local HIGHLIGHT_BLACKLIST_TYPE_MATCHERS = {
  "body",
  "block",
  "haskell:imports",
  "haskell:declarations",
}

local AUGMENT_TARGET_TYPE_MATCHERS = {
  "comment",
  "source",         -- On Ubuntu, on nvim 0.11, TS is diff for comments, with source as the child of comment
  "text",           -- Same as above but with java
  "attribute_item", -- decorators (rust)
  "decorat",        -- decorators (py)
}

local M = {}

---Get the parser name for the current buffer
---@return string|nil
local function get_parser_name()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return nil
  end

  local ok_lang, lang = pcall(parser.lang, parser)
  if not ok_lang then
    return nil
  end

  return lang
end

---@param node TSNode
---@param matchers string[]
---@return boolean
local function is_matched_in(node, matchers)
  local parser_name = get_parser_name()

  for _, matcher in ipairs(matchers) do
    if matcher:find(":") then
      local lang, node_type = matcher:match("([^:]+):(.+)")
      if parser_name and lang == parser_name and node:type():match(node_type) then
        return true
      end
    else
      if node:type():match(matcher) then
        return true
      end
    end
  end

  return false
end

---@param node TSNode
---@return boolean
local function is_root_node(node)
  return node:parent() == nil and node:range() == 0
end

---@param node TSNode
---@return boolean
function M.is_jump_target(node)
  return not is_matched_in(node, TARGET_BLACKLIST_TYPE_MATCHERS) and not is_root_node(node)
end

---@param node TSNode
---@return boolean
function M.is_highlight_target(node)
  return not is_matched_in(node, HIGHLIGHT_BLACKLIST_TYPE_MATCHERS) and not is_root_node(node)
end

---@param node TSNode
---@return boolean
function M.is_augment_target(node)
  return is_matched_in(node, AUGMENT_TARGET_TYPE_MATCHERS) and not is_root_node(node)
end

---@param node TSNode
---@return boolean
function M.is_comment_node(node)
  return node:type():match("comment") or node:type():match("source") or node:type():match("text")
end

return M
