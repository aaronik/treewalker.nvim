-- Helper for emitting deprecation warnings only once per session
local deprecation = {}

local warned = {}

--- Emits the given warning only once per session for the specified key
--- @param key string Unique key for the warning (e.g., module name)
--- @param message string The warning message
function deprecation.warn_once(key, message)
  if warned[key] then return end
  warned[key] = true
  if vim and vim.notify then
    vim.notify(message, vim.log.levels.WARN)
  end
end

--- Convenience: Deprecate a module by warning once and returning the new module's table
--- @param old_name string Name of the deprecated module (for uniqueness)
--- @param message string Deprecation warning
--- @param new_mod string Name of the new module to require
function deprecation.deprecate_module(old_name, message, new_mod)
  deprecation.warn_once(old_name, message)
  return require(new_mod)
end

return deprecation
