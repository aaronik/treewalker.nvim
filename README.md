![build status](https://github.com/aaronik/treewalker.nvim/actions/workflows/test.yml/badge.svg)
<span style="height: 20px;">
  <img alt="Static Badge" src="https://img.shields.io/badge/100%25_lua-purple" style="height: 20px;">
</span>
<a href="https://neovim.io/" style="vertical-align: middle;"><img src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&amp;style=for-the-badge&amp;logo=neovim&amp;logoColor=white" alt="Neovim" style="height: 20px;"></a>

# Treewalker.nvim

![A demo of moving around some code quickly using the plugin](static/fast_demo.gif)

Treewalker is a plugin that gives you the ability to **move around your code in a syntax tree aware manner**.
It uses [Treesitter](https://github.com/tree-sitter/tree-sitter) under the hood for syntax tree awareness.
It offers six subcommands: Up, Down, Right, and Left for movement, and SwapUp and SwapDown for intelligent node swapping.

Each movement command moves you through the syntax tree in an intuitive way.

* **Up/Down** - Moves up or down to the next neighbor node
* **Right** - Finds the next good child node
* **Left** - Finds the next good parent node

The swap commands intelligently swap nodes, including comments and attributes/decorators.

---

<details>
<summary>Typing out the Move commands manually</summary>
<img src="static/slow_move_demo.gif" alt="A demo of moving around some code slowly typing out each Treewalker move command">
</details>

<details>
<summary>Typing out the Swap commands manually</summary>
<img src="static/slow_swap_demo.gif" alt="A demo of swapping code slowly using Treewalker swap commands">
</details>

---

### Installation

##### Lazy:
```lua
{
  "aaronik/treewalker.nvim",
  opts = {
    highlight = true, -- Whether to briefly highlight the node after jumping to it
    highlight_duration = 250, -- How long should above highlight last (in ms)
    highlight_group = "ColorColumn", -- Highlight group 
  }
}
```

#### Mapping

This is how I have mine mapped; in `init.lua`:

```lua
vim.keymap.set({ 'n', 'v' }, '<C-k>', '<cmd>Treewalker Up<cr>', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-j>', '<cmd>Treewalker Down<cr>', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-l>', '<cmd>Treewalker Right<cr>', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-h>', '<cmd>Treewalker Left<cr>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-S-j>', '<cmd>Treewalker SwapDown<cr>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-S-k>', '<cmd>Treewalker SwapUp<cr>', { noremap = true, silent = true })
```

I also utilize some
[nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects?tab=readme-ov-file#text-objects-swap)
commands to round out the swap commands - `<C-S-{j,k,l,h}>` just feel really good to me, so might as well get the
lateral swapping as well. (This is not something that `Treewalker` needs to do as it already exists from other libraries)

```lua
vim.keymap.set('n', "<C-S-l>", ":TSTextobjectSwapNext @parameter.inner<CR>", { noremap = true, silent = true })
vim.keymap.set('n', "<C-S-h>", ":TSTextobjectSwapPrevious @parameter.inner<CR>", { noremap = true, silent = true })
```

The above can also be accomplished with
[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) using
[ts_utils](https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#utilities).
See [this PR](https://github.com/aaronik/treewalker.nvim/pull/10/files) for
an example of that!
