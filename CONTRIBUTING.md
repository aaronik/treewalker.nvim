# Contributing

Thank you for contributing to Treewalker!

## Getting started

- Development in this repo assumes `lazy.nvim`, as used by `tests/minimal_init.lua`
- Install `plenary.nvim` and `nvim-treesitter` through lazy in your local Neovim setup
- In your lazy config, set `dir = "<path-to-treewalker.nvim>"`
- For live reloading while developing the plugin commands, start Neovim with `TREEWALKER_NVIM_ENV=development`

## Commands to know

- `make test` runs the full test suite
- `make check` runs `luacheck`
- `make no-utils` runs the rogue util call check
- `make pass` runs all of the above <-- If this passes, CI should pass

- `make test-watch` reruns tests on Lua file changes using `nodemon`
- `make dump-treesitter-tree FILE=tests/fixtures/markdown.md` prints a fixture's Treesitter tree

- `make help` lists available tasks

## Debugging

- Use `require("treewalker.util").log_file(...)` to write to `~/.local/share/nvim/treewalker/debug.log`
- Use `require("treewalker.util").log(...)` to echo debug information in Neovim
- `tail -f ~/.local/share/nvim/treewalker/debug.log` is handy while iterating

## Testing notes

- Tests use Plenary and the minimal config in `tests/minimal_init.lua`
- Fixtures live in `tests/fixtures/`
- If you change movement or swap behavior, add or update high-level fixture-based tests
