local lazypath = vim.fn.stdpath("data") .. "/lazy"
vim.notify = print
vim.opt.rtp:append(".")
vim.opt.rtp:append(lazypath .. "/plenary.nvim")
vim.opt.rtp:append(lazypath .. "/nvim-treesitter")

vim.opt.swapfile = false

vim.cmd("runtime! plugin/treewalker.nvim")
vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/nvim-treesitter")

-- nvim-treesitter renamed `nvim-treesitter.configs` -> `nvim-treesitter.config`.
-- Keep tests working across versions.
local ok, ts_config = pcall(require, "nvim-treesitter.configs")
if not ok then
  ts_config = require("nvim-treesitter.config")
end

ts_config.setup {
    ensure_installed = {
        "lua",
        "c",
        "python",
        "rust",
        "haskell",
        "html",
        "javascript",
        "c_sharp",
        "typescript",
        "php",
        "markdown",
        "ruby",
        "scheme",
        "yaml",
        "java",
        "go",
    },
    sync_install = true,
    auto_install = true,
    ignore_install = {},
    modules = {}
}

-- These are required lest nvim not be able to tell these parsers are
-- installed. I'm not sure why some of these are required and some aren't.
vim.treesitter.language.register('python', { 'py' })
vim.treesitter.language.register('rust', { 'rs' })
vim.treesitter.language.register('haskell', { 'hs' })
vim.treesitter.language.register('javascript', { 'js' })
vim.treesitter.language.register('c_sharp', { 'cs' })
vim.treesitter.language.register('typescript', { 'ts' })
vim.treesitter.language.register('markdown', { 'md' })
vim.treesitter.language.register('ruby', { 'rb' })
vim.treesitter.language.register('scheme', { 'scm' })
vim.treesitter.language.register('yaml', { 'yml' })
vim.treesitter.language.register('go', { 'go' })

dofile("plugin/init.lua") -- get the Treewalker command present
