local lazypath = vim.fn.stdpath("data") .. "/lazy"
vim.notify = print
vim.opt.rtp:append(".")
vim.opt.rtp:append(lazypath .. "/plenary.nvim")
vim.opt.rtp:append(lazypath .. "/nvim-treesitter")

vim.opt.swapfile = false

vim.cmd("runtime! plugin/treewalker.nvim")
vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/nvim-treesitter")
require('nvim-treesitter.configs').setup {
    ensure_installed = {
        "lua",
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
    },
    sync_install = true,
    auto_install = true,
    ignore_install = {},
    modules = {}
}

-- These are required lest nvim not be able to tell these parsers are installed
vim.treesitter.language.register('ruby', { 'rb' })
vim.treesitter.language.register('markdown', { 'md' })

dofile("plugin/init.lua") -- get the Treewalker command present
