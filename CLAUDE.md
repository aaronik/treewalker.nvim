# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Treewalker.nvim is a Neovim plugin for syntax tree-aware code navigation and manipulation. It leverages Neovim's built-in Treesitter integration to provide movement and swap operations that respect the code's syntax structure rather than just line-by-line navigation.

Core features:
- Movement commands (Up, Down, Left, Right)
- Swap commands (SwapUp, SwapDown, SwapLeft, SwapRight)

## Development Commands

```bash
# Run all tests
make test

# Run style checks with luacheck
make check

# Check for rogue utility calls
make no-utils

# Run all checks and tests (combination of all of the above)
make pass
```

## Testing

Every new feature added to this repository is meticulously tested in multiple languages.

Tests use Plenary.nvim's busted-style framework (describe, it, before_each) and rely on:
- `minimal_init.lua` for setting up the test environment
- `fixtures/` directory containing test files for various languages
- `helpers.lua` with utility functions for tests
- `load_fixture.lua` to prepare test buffers

Each test spec focuses on a specific language or feature, loading the appropriate fixture and verifying cursor movement and text manipulation behavior.

## Linting

The linter doesn't like whitespace at the end of rows, so avoid leaving it

## Architecture

The plugin is organized into several core components:

1. **Movement System** (`movement.lua`, `targets.lua`, `strategies.lua`)
   - Handles cursor movement through code structure
   - Determines target nodes for different movement directions
   - Implements node selection strategies

2. **Node Operations** (`nodes.lua`, `operations.lua`)
   - Core utilities for working with treesitter nodes
   - Implements highlighting and jumping operations

3. **Code Manipulation** (`swap.lua`, `lines.lua`)
   - Implements code swapping functionality
   - Provides utilities for working with buffer lines

4. **Configuration** (`options.lua`)
   - Manages plugin options and default settings

5. **Support Utilities** (`util.lua`, `augment.lua`)
   - General utility functions and logging
   - Node augmentation for related nodes (comments, decorators)

6. **Markdown Support** (`markdown/` directory)
   - Treesitter-based markdown heading navigation and manipulation
   - Heading level detection, section bounds calculation, navigation selectors
   - Pure treesitter implementation without line-based fallbacks

## Debugging

- Debug logs are written to `~/.local/share/nvim/treewalker/debug.log`
- Use `util.log(message)` to add debug messages
- For node inspection, use `nodes.log(node)` and `nodes.log_parents(node)`

## Directives

Consider yourself a senior engineer who specializes in writing clean code, which is wisely commented, easy to read, and still correctly abstracted. It should be a joy to read.

- Make sure all code changes successfully pass the following checks:
    - Always test code changes with `make test`
    - Always luacheck code changes with `make check`
    - Always use your LSP capabilities and make sure there are no LSP diagnostics

    If any of these fail, update the code until they pass.
    Only run these checks - don't do no-utils or pass

- Never remove existing comments
- Only comment on strange pieces of code, be minimal
- Add types for all code
    - Avoid using `table`, prefer being explicit, ex ---@return { foo: string, bar?: integer }
