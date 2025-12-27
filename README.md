<div align="center">
    <h1>Treewalker.nvim<br><br>🌳🌲🌴🌲🌴🌳</h1>
    <h4 align="center">
        <a href="#Installation">Installation</a>
        ·
        <a href="#Options">Options</a>
        ·
        <a href="#Mapping">Mapping</a>
    </h4>
    <a href="https://neovim.io/">
        <img alt="Neovim" style="height: 20px;" src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&amp;style=for-the-badge&amp;logo=neovim&amp;logoColor=white">
    </a>
    <img alt="100% Lua" src="https://img.shields.io/badge/100%25_lua-purple" height="20px">
    <span>&nbsp;</span>
    <img src="https://github.com/aaronik/treewalker.nvim/actions/workflows/test.yml/badge.svg" alt="build status">
    <img src="https://img.shields.io/github/issues/aaronik/treewalker.nvim/bug?label=bugs" alt="GitHub issues by-label">
    <img src="https://img.shields.io/github/issues-pr/aaronik/treewalker.nvim" alt="GitHub Pull Requests">
</div>

<br>

<div align="center">
    <img src="https://github.com/user-attachments/assets/4d23af49-bd94-412a-bc8c-d546df6775df" alt="A fast paced demo of Treewalker.nvim">
</div>

<div align="center">
    <h2>Move around your code in a syntax tree aware manner.</h2>
    <p>
        Treewalker uses neovim's native <a href="https://github.com/tree-sitter/tree-sitter">Treesitter</a>
        under the hood to enable movement around and swapping of code objects like
        functions, blocks, and statements.
        <br/>
        Design goals include stability, ergonomics, and simplicity.
        <br/>
        Made in 100% Lua, with no dependencies.
    </p>
</div>

---

## Movement

The movement commands move you through code in an intuitive way, skipping nodes that aren't conducive to nimble movement through code:

* **`:Treewalker Up`** - Moves up to the previous neighbor node
* **`:Treewalker Down`** - Moves down to the next neighbor node
* **`:Treewalker Left`** - Moves to the first ancestor node that's on a different line from the current node
* **`:Treewalker Right`** - Moves to the next node down that's indented further than the current node

For markdown files, Treewalker navigates around headings (#, ##, etc.)

All movement commands by default add to the [`jumplist`](https://neovim.io/doc/user/motion.html#jumplist), so if you use a movement command
and then feel lost, you have `Ctrl-o` available to bring you back to where you last were.

---

## Swapping

The swapping commands swap whatever node your cursor is on with one of its neighbors.

`Swap{Up,Down}` operate on a linewise basis, **bringing along nodes' comments, decorators, and annotations**.
These are meant for swapping declarations and definitions - things that take up whole lines.

`Swap{Left,Right}` operate on a literal nodewise basis, and are meant for swapping function arguments, enum members,
list elements, etc -- things that are many per line. If used on a top level node on a line, it'll swap
the same nodes as Up/Down, but won't take the comments, decorators or annotations with them.

* **`:Treewalker SwapUp`** - Swaps the highest node on the line upwards in the document
* **`:Treewalker SwapDown`** - Swaps the highest node on the line downward in the document
* **`:Treewalker SwapLeft`** - Swap the node under the cursor with its previous neighbor
* **`:Treewalker SwapRight`** - Swap the node under the cursor with its next neighbor

---

## More Examples

<details>
<summary>Typing out the Move commands manually</summary>
<img src="static/slow_move_demo.gif" alt="A demo of moving around some code slowly typing out each Treewalker move command">
</details>

<details>
<summary>Typing out the SwapUp/SwapDown commands manually</summary>
<img src="static/slow_swap_demo.gif" alt="A demo of swapping code slowly using Treewalker swap commands">
</details>

---

## Installation

#### [Lazy](https://github.com/folke/lazy.nvim)
```lua
{
  'aaronik/treewalker.nvim',

  -- optional (see options below)
  opts = { ... }
}
```

#### [Packer](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'aaronik/treewalker.nvim',

  -- optional (see options below)
  setup = function()
      require('treewalker').setup({ ... })
  end
}
```

#### [Vim-plug](https://github.com/junegunn/vim-plug)
```vimscript
Plug 'aaronik/treewalker.nvim'

" Optionally (see options below)
:lua require('treewalker').setup({ ... })
```

---

## Options

Treewalker aims for sane behavior, but you can modify some via the options below.

```lua
-- The defaults:
{
  -- Whether to briefly highlight the node after jumping to it
  highlight = true,

  -- How long should above highlight last (in ms)
  highlight_duration = 250,

  -- The color of the above highlight. Must be a valid vim highlight group.
  -- (see :h highlight-group for options)
  highlight_group = 'CursorLine',

  -- Whether to create a visual selection after a movement to a node.
  -- If true, highlight is disabled and a visual selection is made in
  -- its place.
  select = false,

  -- Whether to use vim.notify to warn when there are missing parsers or incorrect options
  notifications = true,

  -- Whether the plugin adds movements to the jumplist -- true | false | 'left'
  --  true: All movements more than 1 line are added to the jumplist. This is the default,
  --        and is meant to cover most use cases. It's modeled on how { and } natively add
  --        to the jumplist.
  --  false: Treewalker does not add to the jumplist at all
  --  "left": Treewalker only adds :Treewalker Left to the jumplist. This seems the most
  --          likely jump to cause location confusion, so use this to minimize writes
  --          to the jumplist, while maintaining some ability to go back.
  jumplist = true,

  -- Whether movement, when inside the scope of some node, should be confined to that scope.
  -- When true, when moving through neighboring nodes inside some node, you won't be able to
  -- move outside of that scope via :Treewalker Up/Down. When false, if on a node at the end
  -- of a scope, movement will bring you to the next node of similar indentation/number of
  -- ancestor nodes, even when it is outside of the scope you're currently in.
  scope_confined = false,
}
```

## Mapping

I found Ctrl - h / j / k / l to be a natural flow for this plugin, and adding
Shift to that for swapping felt like a clean follow on. So here are the mappings I use:

In `init.lua`:

```lua
-- movement
vim.keymap.set({ 'n', 'v' }, '<C-k>', '<cmd>Treewalker Up<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-j>', '<cmd>Treewalker Down<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-h>', '<cmd>Treewalker Left<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<C-l>', '<cmd>Treewalker Right<cr>', { silent = true })

-- swapping
vim.keymap.set('n', '<C-S-k>', '<cmd>Treewalker SwapUp<cr>', { silent = true })
vim.keymap.set('n', '<C-S-j>', '<cmd>Treewalker SwapDown<cr>', { silent = true })
vim.keymap.set('n', '<C-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
vim.keymap.set('n', '<C-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })
```

---

## Alternatives

* [syntax-tree-surfer](https://github.com/ziontee113/syntax-tree-surfer)
is publicly archived and I could not get it to work :/
`Treewalker` has a robust test suite, is well typed, and has CI
(automated testing), to help the plugin be stable.
I believe `Treewalker` usage is a little bit simpler and more intuitive.
`Treewalker` is missing the visual selection swap feature that syntax-tree-surfer
has (See [#32](https://github.com/aaronik/treewalker.nvim/issues/32)).

* [nvim-treehopper](https://github.com/mfussenegger/nvim-treehopper)
is similar to Treewalker in that it uses the AST to navigate, but it takes more of a
[leap](https://github.com/ggandor/leap.nvim) like approach, only annotating
interesting nodes. Treewalker provides movements that can be called from anywhere
to interact with neighboring nodes.

* [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
can swap
[a subset of node types](https://github.com/nvim-treesitter/nvim-treesitter-textobjects?tab=readme-ov-file#built-in-textobjects),
but misses some types (ex. rust enums). `Treewalker` is not aware of node type
names, only the structure of the AST, so left/right swaps should work where you
want them to. `nvim-treesitter-textobjects` can also move to nodes, but treats
node types individually, whereas `Treewalker` is agnostic about node types, treating
them all the same, and interacting with the neighboring relevant node.

* [nvim-treesitter.ts_utils](https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua)
offers a programmatic interface for swapping nodes. It works mostly the same as
`Treewalker` under the hood. Some of `Treewalker`'s left/right swapping code is
inspired by `ts_utils`. `Treewalker` operates a little differently though,
picking the highest node with a coinciding start position, vs.
`ts_utils`'s picking the lowest node with a coinciding start position.
Practically, what `Treewalker` offers beyond `ts_utils` is doing the
work of finding the next relevant node and packaging the functionality
into a hopefully nice user experience.

* [tree-climber.nvim](https://github.com/drybalka/tree-climber.nvim)
I discovered long after having made `Treewalker`. It seems to be the most
similar of all of these alternatives. It works mostly the same as `Treewalker`,
but sometimes gets stuck on certain nodes, and navigates to nodes that
don't necessarily seem helpful to go to. In my usage, it seems like
`tree-climber` gives you more fine grained access to each individual
node, and works better than `Treewalker` for navigating the literal
syntax tree. `Treewalker` selects nodes on a more linewise approach,
which enables larger movements to nodes that seem more relevant to
moving around code.

