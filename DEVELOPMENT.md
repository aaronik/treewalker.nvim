# Development

## Testing

You'll need to be using Lazy (sorry, this is lazy myself), otherwise modify the
path at the top of the `minimal_init.lua` file. You'll also need to have `plenary`
and `nvim-treesitter` installed via Lazy to run the tests.

Run the tests:

```sh
make test
```

Also available:

```sh
# Runs all style and type checks, tests, and util checks.
# Equivalent to full CI pass. If this passes, CI should pass too.
make pass

# Print out all the available make commands
make help
```

## Developing

For convenience, Treewalker will live reload if the environment variable
`TREEWALKER_NVIM_ENV` is set to `"development"`. This is the easiest way
to develop Treewalker.

```sh
# ~/.zshrc (etc)
export TREEWALKER_NVIM_ENV=development
```
