MINIMAL_INIT=tests/minimal_init.lua
TESTS_DIR=tests
NO_UTIL_SPEC=checks

.PHONY: test test-watch check no-utils pass test-docker test-docker-build help

test: ## Run the whole test suite
	@nvim \
		--headless \
		--noplugin \
		-u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { timeout = 1000, sequential = true, keep_going = false, minimal_init = '${MINIMAL_INIT}' }"

test-watch: ## uses [nodemon](https://nodemon.io/) - watches for changes to lua files and reruns tests
	@nodemon -e lua -x "$(MAKE) test || exit 1"

check: ## uses [luacheck](https://github.com/mpeterv/luacheck) - checks for any type errors or style issues
	@luacheck . --globals vim it describe before_each after_each --exclude-files tests/fixtures --max-comment-line-length 140

no-utils: ## Make sure there are no errant util calls which write to data directories
	@nvim \
		--headless \
		--noplugin \
		-u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${NO_UTIL_SPEC} { minimal_init = '${MINIMAL_INIT}' }"

pass: test no-utils check ## Run everything, if it's a 0 code, everything's good

test-docker-build: ## Build Docker image for Neovim 0.10 testing
	@docker build -f Dockerfile.neovim-0.10 -t treewalker-nvim-0.10 .

test-docker: test-docker-build ## Run all tests in Docker with Neovim 0.10
	@docker run --rm -v "$(PWD):/workspace" treewalker-nvim-0.10

help: ## Displays this information.
	@printf '%s\n' "Usage: make <command>"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf '\n'

dump-treesitter-tree: ## Prints out the treesitter node tree, ex. make dump-treesitter-tree FILE=tests/fixtures/markdown.md
	@if [ -z "$$FILE" ]; then \
		echo "Usage: make dump-treesitter-tree FILE=path/to/file"; \
	else \
		nvim --headless -c "edit $$FILE" \
			-c "lua vim.treesitter.inspect_tree({ ignore_injections = false })" \
			-c 'lua for _,buf in ipairs(vim.api.nvim_list_bufs()) do if vim.bo[buf].filetype=="query" then local l=vim.api.nvim_buf_get_lines(buf,0,-1,false) for _,line in ipairs(l) do print(line) end end end' \
			-c 'qa!'; \
	fi

